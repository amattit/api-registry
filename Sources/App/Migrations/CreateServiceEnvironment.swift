import Fluent

struct CreateServiceEnvironment: AsyncMigration {
    func prepare(on database: Database) async throws {
        let environmentStatus = try await database.enum("environment_status")
            .case("ACTIVE")
            .case("INACTIVE")
            .create()
        
        try await database.schema("service_environments")
            .id()
            .field("service_id", .uuid, .required, .references("services", "id", onDelete: .cascade))
            .field("code", .string, .required)
            .field("display_name", .string, .required)
            .field("host", .string, .required)
            .field("config", .json)
            .field("status", environmentStatus, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "service_id", "code")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("service_environments").delete()
        try await database.enum("environment_status").delete()
    }
}