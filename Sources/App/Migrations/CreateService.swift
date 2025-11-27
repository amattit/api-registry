import Fluent

struct CreateService: AsyncMigration {
    func prepare(on database: Database) async throws {
        let serviceType = try await database.enum("service_type")
            .case("APPLICATION")
            .case("LIBRARY")
            .case("JOB")
            .case("PROXY")
            .create()
        
        try await database.schema("services")
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("owner", .string, .required)
            .field("tags", .array(of: .string), .required)
            .field("service_type", serviceType, .required)
            .field("supports_database", .bool, .required)
            .field("proxy", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "name")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("services").delete()
        try await database.enum("service_type").delete()
    }
}