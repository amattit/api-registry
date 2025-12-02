import Fluent

struct CreateServiceToServiceDependency: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("service_to_service_dependencies")
            .id()
            .field("consumer_service_id", .uuid, .required, .references("services", "id", onDelete: .cascade))
            .field("provider_service_id", .uuid, .required, .references("services", "id", onDelete: .cascade))
            .field("environment_code", .string)
            .field("description", .string)
            .field("dependency_type", .string, .required)
            .field("config", .json, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "consumer_service_id", "provider_service_id", "environment_code")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("service_to_service_dependencies").delete()
    }
}