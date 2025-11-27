import Fluent

struct CreateServiceDbLink: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("service_db_links")
            .id()
            .field("service_id", .uuid, .required, .references("services", "id", onDelete: .cascade))
            .field("database_id", .uuid, .required, .references("databases", "id", onDelete: .cascade))
            .field("environment_code", .string)
            .field("schema_name", .string)
            .field("connection_override", .json, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "service_id", "database_id", "environment_code")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("service_db_links").delete()
    }
}