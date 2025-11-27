import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) throws {
    // Configure database
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "api_registry"
    ), as: .psql)

    // Configure migrations
    app.migrations.add(CreateService())
    app.migrations.add(CreateServiceEnvironment())
    app.migrations.add(CreateDependency())
    app.migrations.add(CreateServiceDependency())
    app.migrations.add(CreateDatabase())
    app.migrations.add(CreateServiceDbLink())
    app.migrations.add(CreateEndpoint())
    app.migrations.add(CreateEndpointDependency())
    app.migrations.add(CreateEndpointDatabase())

    // Configure middleware
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // Configure routes
    try routes(app)
    
    // Configure server
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init(_:)) ?? 8080
    app.http.server.configuration.hostname = "0.0.0.0"
}