import Fluent

struct CreateEndpointDependency: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let callType = try await database.enum("call_type")
            .case("INTERNAL")
            .case("EXTERNAL")
            .create()
        
        try await database.schema("endpoint_dependencies")
            .id()
            .field("endpoint_id", .uuid, .required, .references("endpoints", "id", onDelete: .cascade))
            .field("dependency_id", .uuid, .required, .references("dependencies", "id", onDelete: .cascade))
            .field("call_type", callType, .required)
            .field("config", .json)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "endpoint_id", "dependency_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("endpoint_dependencies").delete()
        try await database.enum("call_type").delete()
    }
}