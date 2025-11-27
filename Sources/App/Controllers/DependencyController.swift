import Fluent
import Vapor

struct DependencyController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let dependencies = routes.grouped("dependencies")
        
        // Dependency CRUD
        dependencies.post(use: create)
        dependencies.get(use: list)
        dependencies.get(":dependencyId", use: show)
        dependencies.patch(":dependencyId", use: update)
        dependencies.delete(":dependencyId", use: delete)
        
        // Service dependency management
        let services = routes.grouped("services", ":serviceId", "dependencies")
        services.post(use: createServiceDependency)
        services.get(use: listServiceDependencies)
        services.delete(":dependencyId", use: deleteServiceDependency)
    }
    
    // MARK: - Dependency CRUD
    
    func create(req: Request) async throws -> DependencyResponse {
        try CreateDependencyRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateDependencyRequest.self)
        
        // Check if dependency with same name and version already exists
        if let _ = try await Dependency.query(on: req.db)
            .filter(\.$name == createRequest.name)
            .filter(\.$version == createRequest.version)
            .first() {
            throw Abort(.conflict, reason: "Dependency '\(createRequest.name)' version '\(createRequest.version)' already exists")
        }
        
        let dependency = Dependency(
            name: createRequest.name,
            description: createRequest.description,
            version: createRequest.version,
            dependencyType: createRequest.dependencyType,
            config: createRequest.config
        )
        
        try await dependency.save(on: req.db)
        return DependencyResponse(from: dependency)
    }
    
    func list(req: Request) async throws -> [DependencyResponse] {
        let dependencies = try await Dependency.query(on: req.db).all()
        return dependencies.map(DependencyResponse.init)
    }
    
    func show(req: Request) async throws -> DependencyResponse {
        guard let dependencyId = req.parameters.get("dependencyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid dependency ID")
        }
        
        guard let dependency = try await Dependency.find(dependencyId, on: req.db) else {
            throw Abort(.notFound, reason: "Dependency not found")
        }
        
        return DependencyResponse(from: dependency)
    }
    
    func update(req: Request) async throws -> DependencyResponse {
        guard let dependencyId = req.parameters.get("dependencyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid dependency ID")
        }
        
        guard let dependency = try await Dependency.find(dependencyId, on: req.db) else {
            throw Abort(.notFound, reason: "Dependency not found")
        }
        
        try UpdateDependencyRequest.validate(content: req)
        let updateRequest = try req.content.decode(UpdateDependencyRequest.self)
        
        if let name = updateRequest.name {
            dependency.name = name
        }
        if let description = updateRequest.description {
            dependency.description = description
        }
        if let version = updateRequest.version {
            dependency.version = version
        }
        if let dependencyType = updateRequest.dependencyType {
            dependency.dependencyType = dependencyType
        }
        if let config = updateRequest.config {
            dependency.config = config
        }
        
        try await dependency.save(on: req.db)
        return DependencyResponse(from: dependency)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let dependencyId = req.parameters.get("dependencyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid dependency ID")
        }
        
        guard let dependency = try await Dependency.find(dependencyId, on: req.db) else {
            throw Abort(.notFound, reason: "Dependency not found")
        }
        
        try await dependency.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - Service Dependencies
    
    func createServiceDependency(req: Request) async throws -> ServiceDependencyResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        try CreateServiceDependencyRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateServiceDependencyRequest.self)
        
        guard let dependency = try await Dependency.find(createRequest.dependencyId, on: req.db) else {
            throw Abort(.notFound, reason: "Dependency not found")
        }
        
        // Check if service dependency already exists
        if let _ = try await ServiceDependency.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$dependency.$id == createRequest.dependencyId)
            .filter(\.$environmentCode == createRequest.environmentCode)
            .first() {
            throw Abort(.conflict, reason: "Service dependency already exists")
        }
        
        let serviceDependency = ServiceDependency(
            serviceID: serviceId,
            dependencyID: createRequest.dependencyId,
            environmentCode: createRequest.environmentCode,
            configOverride: createRequest.configOverride
        )
        
        try await serviceDependency.save(on: req.db)
        return ServiceDependencyResponse(from: serviceDependency, dependency: dependency)
    }
    
    func listServiceDependencies(req: Request) async throws -> [ServiceDependencyResponse] {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        let serviceDependencies = try await ServiceDependency.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .with(\.$dependency)
            .all()
        
        return serviceDependencies.map { serviceDependency in
            ServiceDependencyResponse(from: serviceDependency, dependency: serviceDependency.dependency)
        }
    }
    
    func deleteServiceDependency(req: Request) async throws -> HTTPStatus {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let dependencyId = req.parameters.get("dependencyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid dependency ID")
        }
        
        let environmentCode = req.query[String.self, at: "environmentCode"]
        
        guard let serviceDependency = try await ServiceDependency.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$dependency.$id == dependencyId)
            .filter(\.$environmentCode == environmentCode)
            .first() else {
            throw Abort(.notFound, reason: "Service dependency not found")
        }
        
        try await serviceDependency.delete(on: req.db)
        return .noContent
    }
}