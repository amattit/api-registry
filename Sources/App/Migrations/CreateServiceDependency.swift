import Fluent

struct CreateServiceDependency: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("service_dependencies")
            .id()
            .field("service_id", .uuid, .required, .references("services", "id", onDelete: .cascade))
            .field("dependency_id", .uuid, .required, .references("dependencies", "id", onDelete: .cascade))
            .field("environment_code", .string)
            .field("config_override", .json, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "service_id", "dependency_id", "environment_code")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("service_dependencies").delete()
    }
}