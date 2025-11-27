import Fluent

struct CreateDependency: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let dependencyType = try await database.enum("dependency_type")
            .case("DATABASE")
            .case("CACHE")
            .case("QUEUE")
            .case("STORAGE")
            .case("EXTERNAL_API")
            .case("LIBRARY")
            .create()
        
        try await database.schema("dependencies")
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("version", .string, .required)
            .field("dependency_type", dependencyType, .required)
            .field("config", .json, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "name", "version")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("dependencies").delete()
        try await database.enum("dependency_type").delete()
    }
}