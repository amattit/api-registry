import Fluent
import Vapor

final class ServiceEnvironment: Model, Content, @unchecked Sendable {
    static let schema = "service_environments"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "service_id")
    var service: Service
    
    @Field(key: "code")
    var code: String
    
    @Field(key: "display_name")
    var displayName: String
    
    @Field(key: "host")
    var host: String
    
    @Field(key: "config")
    var config: EnvironmentConfig?
    
    @Enum(key: "status")
    var status: EnvironmentStatus
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, serviceID: UUID, code: String, displayName: String, host: String, config: EnvironmentConfig? = nil, status: EnvironmentStatus = .ACTIVE) {
        self.id = id
        self.$service.id = serviceID
        self.code = code
        self.displayName = displayName
        self.host = host
        self.config = config
        self.status = status
    }
}

struct EnvironmentConfig: Codable {
    let timeoutMs: Int?
    let retries: Int?
    let downstreamOverrides: [String: String]?
}

enum EnvironmentStatus: String, Codable, CaseIterable {
    case ACTIVE = "ACTIVE"
    case INACTIVE = "INACTIVE"
}