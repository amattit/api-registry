import Fluent

struct CreateDatabase: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let databaseType = try await database.enum("database_type")
            .case("POSTGRESQL")
            .case("MYSQL")
            .case("MONGODB")
            .case("REDIS")
            .case("ELASTICSEARCH")
            .case("CASSANDRA")
            .case("SQLITE")
            .case("ORACLE")
            .case("MSSQL")
            .create()
        
        try await database.schema("databases")
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("database_type", databaseType, .required)
            .field("connection_string", .string, .required)
            .field("config", .json, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "name")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("databases").delete()
        try await database.enum("database_type").delete()
    }
}