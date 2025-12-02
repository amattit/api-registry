import Fluent
import Vapor

struct ServiceToServiceDependencyController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let services = routes.grouped("services", ":serviceId", "service-dependencies")
        
        // Service-to-service dependency management
        services.post(use: createServiceDependency)
        services.get(use: listServiceDependencies)
        services.patch(":dependencyId", use: updateServiceDependency)
        services.delete(":dependencyId", use: deleteServiceDependency)
        
        // Dependency graph endpoints
        let graph = routes.grouped("services", ":serviceId", "dependency-graph")
        graph.get(use: getServiceDependencyGraph)
        
        // Global dependency graph
        routes.get("dependency-graph", use: getGlobalDependencyGraph)
    }
    
    // MARK: - Service-to-Service Dependencies
    
    func createServiceDependency(req: Request) async throws -> ServiceToServiceDependencyResponse {
        guard let consumerServiceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid consumer service ID")
        }
        
        guard let consumerService = try await Service.find(consumerServiceId, on: req.db) else {
            throw Abort(.notFound, reason: "Consumer service not found")
        }
        
        try CreateServiceToServiceDependencyRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateServiceToServiceDependencyRequest.self)
        
        guard let providerService = try await Service.find(createRequest.providerServiceId, on: req.db) else {
            throw Abort(.notFound, reason: "Provider service not found")
        }
        
        // Prevent self-dependency
        if consumerServiceId == createRequest.providerServiceId {
            throw Abort(.badRequest, reason: "Service cannot depend on itself")
        }
        
        // Check if dependency already exists
        if let _ = try await ServiceToServiceDependency.query(on: req.db)
            .filter(\.$consumerService.$id == consumerServiceId)
            .filter(\.$providerService.$id == createRequest.providerServiceId)
            .filter(\.$environmentCode == createRequest.environmentCode)
            .first() {
            throw Abort(.conflict, reason: "Service dependency already exists")
        }
        
        // Check for circular dependencies
        if try await hasCircularDependency(
            from: createRequest.providerServiceId,
            to: consumerServiceId,
            environment: createRequest.environmentCode,
            on: req.db
        ) {
            throw Abort(.badRequest, reason: "Creating this dependency would result in a circular dependency")
        }
        
        let dependency = ServiceToServiceDependency(
            consumerServiceID: consumerServiceId,
            providerServiceID: createRequest.providerServiceId,
            environmentCode: createRequest.environmentCode,
            description: createRequest.description,
            dependencyType: createRequest.dependencyType,
            config: createRequest.config
        )
        
        try await dependency.save(on: req.db)
        return ServiceToServiceDependencyResponse(from: dependency, consumerService: consumerService, providerService: providerService)
    }
    
    func listServiceDependencies(req: Request) async throws -> [ServiceToServiceDependencyResponse] {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        let environmentCode = req.query[String.self, at: "environmentCode"]
        
        var query = ServiceToServiceDependency.query(on: req.db)
            .filter(\.$consumerService.$id == serviceId)
            .with(\.$consumerService)
            .with(\.$providerService)
        
        if let environment = environmentCode {
            query = query.filter(\.$environmentCode == environment)
        }
        
        let dependencies = try await query.all()
        
        return dependencies.map { dependency in
            ServiceToServiceDependencyResponse(
                from: dependency,
                consumerService: dependency.consumerService,
                providerService: dependency.providerService
            )
        }
    }
    
    func updateServiceDependency(req: Request) async throws -> ServiceToServiceDependencyResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let dependencyId = req.parameters.get("dependencyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid dependency ID")
        }
        
        guard let dependency = try await ServiceToServiceDependency.query(on: req.db)
            .filter(\.$id == dependencyId)
            .filter(\.$consumerService.$id == serviceId)
            .with(\.$consumerService)
            .with(\.$providerService)
            .first() else {
            throw Abort(.notFound, reason: "Service dependency not found")
        }
        
        try UpdateServiceToServiceDependencyRequest.validate(content: req)
        let updateRequest = try req.content.decode(UpdateServiceToServiceDependencyRequest.self)
        
        if let environmentCode = updateRequest.environmentCode {
            dependency.environmentCode = environmentCode
        }
        if let description = updateRequest.description {
            dependency.description = description
        }
        if let dependencyType = updateRequest.dependencyType {
            dependency.dependencyType = dependencyType
        }
        if let config = updateRequest.config {
            dependency.config = config
        }
        
        try await dependency.save(on: req.db)
        return ServiceToServiceDependencyResponse(
            from: dependency,
            consumerService: dependency.consumerService,
            providerService: dependency.providerService
        )
    }
    
    func deleteServiceDependency(req: Request) async throws -> HTTPStatus {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let dependencyId = req.parameters.get("dependencyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid dependency ID")
        }
        
        guard let dependency = try await ServiceToServiceDependency.query(on: req.db)
            .filter(\.$id == dependencyId)
            .filter(\.$consumerService.$id == serviceId)
            .first() else {
            throw Abort(.notFound, reason: "Service dependency not found")
        }
        
        try await dependency.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - Dependency Graph
    
    func getServiceDependencyGraph(req: Request) async throws -> ServiceDependencyGraphResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let service = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        let environmentCode = req.query[String.self, at: "environmentCode"]
        
        // Get services this service depends on
        var dependenciesQuery = ServiceToServiceDependency.query(on: req.db)
            .filter(\.$consumerService.$id == serviceId)
            .with(\.$consumerService)
            .with(\.$providerService)
        
        if let environment = environmentCode {
            dependenciesQuery = dependenciesQuery.filter(\.$environmentCode == environment)
        }
        
        let dependencies = try await dependenciesQuery.all()
        let dependencyResponses = dependencies.map { dependency in
            ServiceToServiceDependencyResponse(
                from: dependency,
                consumerService: dependency.consumerService,
                providerService: dependency.providerService
            )
        }
        
        // Get services that depend on this service
        var dependentsQuery = ServiceToServiceDependency.query(on: req.db)
            .filter(\.$providerService.$id == serviceId)
            .with(\.$consumerService)
            .with(\.$providerService)
        
        if let environment = environmentCode {
            dependentsQuery = dependentsQuery.filter(\.$environmentCode == environment)
        }
        
        let dependents = try await dependentsQuery.all()
        let dependentResponses = dependents.map { dependent in
            ServiceToServiceDependencyResponse(
                from: dependent,
                consumerService: dependent.consumerService,
                providerService: dependent.providerService
            )
        }
        
        return ServiceDependencyGraphResponse(
            service: service,
            dependencies: dependencyResponses,
            dependents: dependentResponses
        )
    }
    
    func getGlobalDependencyGraph(req: Request) async throws -> [ServiceToServiceDependencyResponse] {
        let environmentCode = req.query[String.self, at: "environmentCode"]
        
        var query = ServiceToServiceDependency.query(on: req.db)
            .with(\.$consumerService)
            .with(\.$providerService)
        
        if let environment = environmentCode {
            query = query.filter(\.$environmentCode == environment)
        }
        
        let dependencies = try await query.all()
        
        return dependencies.map { dependency in
            ServiceToServiceDependencyResponse(
                from: dependency,
                consumerService: dependency.consumerService,
                providerService: dependency.providerService
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func hasCircularDependency(
        from startServiceId: UUID,
        to targetServiceId: UUID,
        environment: String?,
        on database: Database,
        visited: Set<UUID> = []
    ) async throws -> Bool {
        if visited.contains(startServiceId) {
            return startServiceId == targetServiceId
        }
        
        var newVisited = visited
        newVisited.insert(startServiceId)
        
        var query = ServiceToServiceDependency.query(on: database)
            .filter(\.$consumerService.$id == startServiceId)
        
        if let env = environment {
            query = query.filter(\.$environmentCode == env)
        }
        
        let dependencies = try await query.all()
        
        for dependency in dependencies {
            if try await hasCircularDependency(
                from: dependency.$providerService.id,
                to: targetServiceId,
                environment: environment,
                on: database,
                visited: newVisited
            ) {
                return true
            }
        }
        
        return false
    }
}