import Fluent

struct CreateEndpoint: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let endpointMethod = try await database.enum("endpoint_method")
            .case("GET")
            .case("POST")
            .case("PUT")
            .case("PATCH")
            .case("DELETE")
            .case("HEAD")
            .case("OPTIONS")
            .create()
        
        try await database.schema("endpoints")
            .id()
            .field("service_id", .uuid, .required, .references("services", "id", onDelete: .cascade))
            .field("method", endpointMethod, .required)
            .field("path", .string, .required)
            .field("summary", .string, .required)
            .field("request_schema", .json)
            .field("response_schemas", .json)
            .field("auth", .json)
            .field("rate_limit", .json)
            .field("metadata", .json)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "service_id", "method", "path")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("endpoints").delete()
        try await database.enum("endpoint_method").delete()
    }
}