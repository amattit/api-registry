import Fluent

struct CreateEndpointDatabase: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let operationType = try await database.enum("operation_type")
            .case("READ")
            .case("WRITE")
            .case("READ_WRITE")
            .create()
        
        try await database.schema("endpoint_databases")
            .id()
            .field("endpoint_id", .uuid, .required, .references("endpoints", "id", onDelete: .cascade))
            .field("database_id", .uuid, .required, .references("databases", "id", onDelete: .cascade))
            .field("operation_type", operationType, .required)
            .field("table_names", .json)
            .field("config", .json)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "endpoint_id", "database_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("endpoint_databases").delete()
        try await database.enum("operation_type").delete()
    }
}