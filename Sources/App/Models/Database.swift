import Fluent
import Vapor

enum DatabaseType: String, Codable, CaseIterable, @unchecked Sendable {
    case POSTGRESQL = "POSTGRESQL"
    case MYSQL = "MYSQL"
    case MONGODB = "MONGODB"
    case REDIS = "REDIS"
    case ELASTICSEARCH = "ELASTICSEARCH"
    case CASSANDRA = "CASSANDRA"
    case SQLITE = "SQLITE"
    case ORACLE = "ORACLE"
    case MSSQL = "MSSQL"
}

final class DatabaseInstance: Model, Content, @unchecked Sendable {
    static let schema = "databases"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Enum(key: "database_type")
    var databaseType: DatabaseType
    
    @Field(key: "connection_string")
    var connectionString: String
    
    @Field(key: "config")
    var config: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // Relationships
    @Children(for: \.$database)
    var serviceDbLinks: [ServiceDbLink]
    
    init() { }
    
    init(id: UUID? = nil, name: String, description: String? = nil, databaseType: DatabaseType, connectionString: String, config: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.databaseType = databaseType
        self.connectionString = connectionString
        self.config = config
    }
}