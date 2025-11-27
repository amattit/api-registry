import Fluent
import Vapor

struct EndpointController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let endpoints = routes.grouped("services", ":serviceId", "endpoints")
        endpoints.get(use: index)
        endpoints.post(use: create)
        endpoints.group(":endpointId") { endpoint in
            endpoint.get(use: show)
            endpoint.put(use: update)
            endpoint.delete(use: delete)
        }
    }
    
    func index(req: Request) async throws -> [EndpointResponse] {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        // Verify service exists
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        let endpoints = try await Endpoint.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .with(\.$endpointDependencies) { dependency in
                dependency.with(\.$dependency)
            }
            .with(\.$endpointDatabases) { database in
                database.with(\.$database)
            }
            .all()
        
        return try endpoints.map { endpoint in
            let calls = try endpoint.endpointDependencies.map { endpointDep in
                EndpointCallResponse(from: endpointDep, dependency: endpointDep.dependency)
            }
            
            let databases = try endpoint.endpointDatabases.map { endpointDb in
                EndpointDatabaseResponse(from: endpointDb, database: endpointDb.database)
            }
            
            return EndpointResponse(from: endpoint, calls: calls, databases: databases)
        }
    }
    
    func show(req: Request) async throws -> EndpointResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let endpointId = req.parameters.get("endpointId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid endpoint ID")
        }
        
        let endpointQuery = try await Endpoint.query(on: req.db)
            .filter(\.$id == endpointId)
            .filter(\.$service.$id == serviceId)
            .with(\.$endpointDependencies) { dependency in
                dependency.with(\.$dependency)
            }
            .with(\.$endpointDatabases) { database in
                database.with(\.$database)
            }
            .first()
        
        guard let endpoint = endpointQuery else {
            throw Abort(.notFound, reason: "Endpoint not found")
        }
        
        let calls = try endpoint.endpointDependencies.map { endpointDep in
            EndpointCallResponse(from: endpointDep, dependency: endpointDep.dependency)
        }
        
        let databases = try endpoint.endpointDatabases.map { endpointDb in
            EndpointDatabaseResponse(from: endpointDb, database: endpointDb.database)
        }
        
        return EndpointResponse(from: endpoint, calls: calls, databases: databases)
    }
    
    func create(req: Request) async throws -> EndpointResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        // Verify service exists
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        try CreateEndpointRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateEndpointRequest.self)
        
        // Check if endpoint with same method and path already exists for this service
        if let _ = try await Endpoint.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$method == createRequest.method)
            .filter(\.$path == createRequest.path)
            .first() {
            throw Abort(.conflict, reason: "Endpoint with this method and path already exists for this service")
        }
        
        let endpoint = Endpoint(
            serviceId: serviceId,
            method: createRequest.method,
            path: createRequest.path,
            summary: createRequest.summary,
            requestSchema: createRequest.requestSchema,
            responseSchemas: createRequest.responseSchemas,
            auth: createRequest.auth,
            rateLimit: createRequest.rateLimit,
            metadata: createRequest.metadata
        )
        
        try await endpoint.save(on: req.db)
        
        // Create endpoint dependencies
        var endpointCalls: [EndpointCallResponse] = []
        if let calls = createRequest.calls {
            for call in calls {
                // Verify dependency exists
                guard let dependency = try await Dependency.find(call.dependencyId, on: req.db) else {
                    throw Abort(.notFound, reason: "Dependency not found: \(call.dependencyId)")
                }
                
                let endpointDependency = EndpointDependency(
                    endpointId: endpoint.id!,
                    dependencyId: call.dependencyId,
                    callType: call.callType,
                    config: call.config
                )
                
                try await endpointDependency.save(on: req.db)
                endpointCalls.append(EndpointCallResponse(from: endpointDependency, dependency: dependency))
            }
        }
        
        // Create endpoint databases
        var endpointDatabases: [EndpointDatabaseResponse] = []
        if let databases = createRequest.databases {
            for db in databases {
                // Verify database exists
                guard let database = try await DatabaseInstance.find(db.databaseId, on: req.db) else {
                    throw Abort(.notFound, reason: "Database not found: \(db.databaseId)")
                }
                
                let endpointDatabase = EndpointDatabase(
                    endpointId: endpoint.id!,
                    databaseId: db.databaseId,
                    operationType: db.operationType,
                    tableNames: db.tableNames,
                    config: db.config
                )
                
                try await endpointDatabase.save(on: req.db)
                endpointDatabases.append(EndpointDatabaseResponse(from: endpointDatabase, database: database))
            }
        }
        
        return EndpointResponse(from: endpoint, calls: endpointCalls, databases: endpointDatabases)
    }
    
    func update(req: Request) async throws -> EndpointResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let endpointId = req.parameters.get("endpointId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid endpoint ID")
        }
        
        guard let endpoint = try await Endpoint.query(on: req.db)
            .filter(\.$id == endpointId)
            .filter(\.$service.$id == serviceId)
            .first() else {
            throw Abort(.notFound, reason: "Endpoint not found")
        }
        
        try UpdateEndpointRequest.validate(content: req)
        let updateRequest = try req.content.decode(UpdateEndpointRequest.self)
        
        // Check for conflicts if method or path is being updated
        if let method = updateRequest.method, let path = updateRequest.path {
            if let _ = try await Endpoint.query(on: req.db)
                .filter(\.$service.$id == serviceId)
                .filter(\.$method == method)
                .filter(\.$path == path)
                .filter(\.$id != endpointId)
                .first() {
                throw Abort(.conflict, reason: "Endpoint with this method and path already exists for this service")
            }
        }
        
        if let method = updateRequest.method {
            endpoint.method = method
        }
        if let path = updateRequest.path {
            endpoint.path = path
        }
        if let summary = updateRequest.summary {
            endpoint.summary = summary
        }
        if let requestSchema = updateRequest.requestSchema {
            endpoint.requestSchema = requestSchema
        }
        if let responseSchemas = updateRequest.responseSchemas {
            endpoint.responseSchemas = responseSchemas
        }
        if let auth = updateRequest.auth {
            endpoint.auth = auth
        }
        if let rateLimit = updateRequest.rateLimit {
            endpoint.rateLimit = rateLimit
        }
        if let metadata = updateRequest.metadata {
            endpoint.metadata = metadata
        }
        
        try await endpoint.save(on: req.db)
        
        // Load relationships for response
        let updatedEndpoint = try await Endpoint.query(on: req.db)
            .filter(\.$id == endpointId)
            .with(\.$endpointDependencies) { dependency in
                dependency.with(\.$dependency)
            }
            .with(\.$endpointDatabases) { database in
                database.with(\.$database)
            }
            .first()!
        
        let calls = try updatedEndpoint.endpointDependencies.map { endpointDep in
            EndpointCallResponse(from: endpointDep, dependency: endpointDep.dependency)
        }
        
        let databases = try updatedEndpoint.endpointDatabases.map { endpointDb in
            EndpointDatabaseResponse(from: endpointDb, database: endpointDb.database)
        }
        
        return EndpointResponse(from: updatedEndpoint, calls: calls, databases: databases)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let endpointId = req.parameters.get("endpointId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid endpoint ID")
        }
        
        guard let endpoint = try await Endpoint.query(on: req.db)
            .filter(\.$id == endpointId)
            .filter(\.$service.$id == serviceId)
            .first() else {
            throw Abort(.notFound, reason: "Endpoint not found")
        }
        
        try await endpoint.delete(on: req.db)
        return .noContent
    }
}