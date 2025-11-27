import Fluent
import Vapor

final class ServiceDbLink: Model, Content, @unchecked Sendable {
    static let schema = "service_db_links"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "service_id")
    var service: Service
    
    @Parent(key: "database_id")
    var database: DatabaseInstance
    
    @Field(key: "environment_code")
    var environmentCode: String?
    
    @Field(key: "schema_name")
    var schemaName: String?
    
    @Field(key: "connection_override")
    var connectionOverride: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, serviceID: UUID, databaseID: UUID, environmentCode: String? = nil, schemaName: String? = nil, connectionOverride: [String: String] = [:]) {
        self.id = id
        self.$service.id = serviceID
        self.$database.id = databaseID
        self.environmentCode = environmentCode
        self.schemaName = schemaName
        self.connectionOverride = connectionOverride
    }
}