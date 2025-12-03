import Fluent
import Vapor

func routes(_ app: Application) throws {
    // Health check endpoint
    app.get("health") { req async throws -> [String: String] in
        do {
            _ = try await Service.query(on: req.db).count()
            return [
                "status": "healthy",
                "database": "connected",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        } catch {
            return [
                "status": "unhealthy", 
                "database": "disconnected",
                "error": error.localizedDescription,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        }
    }

    // API v1 routes
    let api = app.grouped("api", "v1")
    
    // Service routes
    try api.register(collection: SimpleServiceController())
    
    // Dependency routes
    try api.register(collection: DependencyController())
    
    // Service-to-Service dependency routes
    try api.register(collection: ServiceToServiceDependencyController())
    
    // Database routes
    try api.register(collection: DatabaseController())
    
    // Endpoint routes
    try api.register(collection: EndpointController())
    
    // Dependency graph routes
    try api.register(collection: DependencyGraphController())
    
    // OpenAPI loader routes
    try api.register(collection: OpenAPILoaderController())
}