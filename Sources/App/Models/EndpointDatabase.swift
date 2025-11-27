import Fluent
import Vapor

enum OperationType: String, Codable, CaseIterable {
    case READ = "READ"
    case write = "WRITE"
    case readWrite = "READ_WRITE"
}

final class EndpointDatabase: Model, Content, @unchecked Sendable {
    static let schema = "endpoint_databases"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "endpoint_id")
    var endpoint: Endpoint
    
    @Parent(key: "database_id")
    var database: DatabaseInstance
    
    @Enum(key: "operation_type")
    var operationType: OperationType
    
    @OptionalField(key: "table_names")
    var tableNames: [String]?
    
    @OptionalField(key: "config")
    var config: [String: AnyCodable]?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, endpointId: UUID, databaseId: UUID, operationType: OperationType,
         tableNames: [String]? = nil, config: [String: AnyCodable]? = nil) {
        self.id = id
        self.$endpoint.id = endpointId
        self.$database.id = databaseId
        self.operationType = operationType
        self.tableNames = tableNames
        self.config = config
    }
}