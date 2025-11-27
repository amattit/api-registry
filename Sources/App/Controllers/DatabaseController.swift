import Fluent
import Vapor

struct DatabaseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let databases = routes.grouped("databases")
        
        // Database CRUD
        databases.post(use: create)
        databases.get(use: list)
        databases.get(":databaseId", use: show)
        databases.patch(":databaseId", use: update)
        databases.delete(":databaseId", use: delete)
        
        // Service database link management
        let services = routes.grouped("services", ":serviceId", "databases")
        services.post(use: createServiceDbLink)
        services.get(use: listServiceDbLinks)
        services.delete(":databaseId", use: deleteServiceDbLink)
    }
    
    // MARK: - Database CRUD
    
    func create(req: Request) async throws -> DatabaseResponse {
        try CreateDatabaseRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateDatabaseRequest.self)
        
        // Check if database with same name already exists
        if let _ = try await DatabaseInstance.query(on: req.db)
            .filter(\.$name == createRequest.name)
            .first() {
            throw Abort(.conflict, reason: "Database '\(createRequest.name)' already exists")
        }
        
        let database = DatabaseInstance(
            name: createRequest.name,
            description: createRequest.description,
            databaseType: createRequest.databaseType,
            connectionString: createRequest.connectionString,
            config: createRequest.config
        )
        
        try await database.save(on: req.db)
        return DatabaseResponse(from: database)
    }
    
    func list(req: Request) async throws -> [DatabaseResponse] {
        let databases = try await DatabaseInstance.query(on: req.db).all()
        return databases.map(DatabaseResponse.init)
    }
    
    func show(req: Request) async throws -> DatabaseResponse {
        guard let databaseId = req.parameters.get("databaseId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid database ID")
        }
        
        guard let database = try await DatabaseInstance.find(databaseId, on: req.db) else {
            throw Abort(.notFound, reason: "Database not found")
        }
        
        return DatabaseResponse(from: database)
    }
    
    func update(req: Request) async throws -> DatabaseResponse {
        guard let databaseId = req.parameters.get("databaseId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid database ID")
        }
        
        guard let database = try await DatabaseInstance.find(databaseId, on: req.db) else {
            throw Abort(.notFound, reason: "Database not found")
        }
        
        try UpdateDatabaseRequest.validate(content: req)
        let updateRequest = try req.content.decode(UpdateDatabaseRequest.self)
        
        if let name = updateRequest.name {
            database.name = name
        }
        if let description = updateRequest.description {
            database.description = description
        }
        if let databaseType = updateRequest.databaseType {
            database.databaseType = databaseType
        }
        if let connectionString = updateRequest.connectionString {
            database.connectionString = connectionString
        }
        if let config = updateRequest.config {
            database.config = config
        }
        
        try await database.save(on: req.db)
        return DatabaseResponse(from: database)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let databaseId = req.parameters.get("databaseId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid database ID")
        }
        
        guard let database = try await DatabaseInstance.find(databaseId, on: req.db) else {
            throw Abort(.notFound, reason: "Database not found")
        }
        
        try await database.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - Service Database Links
    
    func createServiceDbLink(req: Request) async throws -> ServiceDbLinkResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        try CreateServiceDbLinkRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateServiceDbLinkRequest.self)
        
        guard let database = try await DatabaseInstance.find(createRequest.databaseId, on: req.db) else {
            throw Abort(.notFound, reason: "Database not found")
        }
        
        // Check if service database link already exists
        if let _ = try await ServiceDbLink.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$database.$id == createRequest.databaseId)
            .filter(\.$environmentCode == createRequest.environmentCode)
            .first() {
            throw Abort(.conflict, reason: "Service database link already exists")
        }
        
        let serviceDbLink = ServiceDbLink(
            serviceID: serviceId,
            databaseID: createRequest.databaseId,
            environmentCode: createRequest.environmentCode,
            schemaName: createRequest.schemaName,
            connectionOverride: createRequest.connectionOverride
        )
        
        try await serviceDbLink.save(on: req.db)
        return ServiceDbLinkResponse(from: serviceDbLink, database: database)
    }
    
    func listServiceDbLinks(req: Request) async throws -> [ServiceDbLinkResponse] {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        let serviceDbLinks = try await ServiceDbLink.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .with(\.$database)
            .all()
        
        return serviceDbLinks.map { serviceDbLink in
            ServiceDbLinkResponse(from: serviceDbLink, database: serviceDbLink.database)
        }
    }
    
    func deleteServiceDbLink(req: Request) async throws -> HTTPStatus {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let databaseId = req.parameters.get("databaseId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid database ID")
        }
        
        let environmentCode = req.query[String.self, at: "environmentCode"]
        
        guard let serviceDbLink = try await ServiceDbLink.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$database.$id == databaseId)
            .filter(\.$environmentCode == environmentCode)
            .first() else {
            throw Abort(.notFound, reason: "Service database link not found")
        }
        
        try await serviceDbLink.delete(on: req.db)
        return .noContent
    }
}