import Fluent
import FluentPostgresDriver
import Vapor
import APIDocumentationManager
import DBDocumentationKit

public func configure(_ app: Application) throws {
    // Configure database
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "api_registry"
    ), as: .psql)

    try DBDocumentationKit.configure(app, configuration: .init())
    try APIDocumentationKit.configure(app, configuration: .init())

    // Configure middleware
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Configure routes
    try routes(app)
    
    // Configure server
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init(_:)) ?? 8080
    app.http.server.configuration.hostname = "0.0.0.0"
}
