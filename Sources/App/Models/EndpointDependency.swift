import Fluent
import Vapor

enum CallType: String, Codable, CaseIterable {
    case INTERNAL = "INTERNAL"
    case EXTERNAL = "EXTERNAL"
}

final class EndpointDependency: Model, Content, @unchecked Sendable {
    static let schema = "endpoint_dependencies"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "endpoint_id")
    var endpoint: Endpoint
    
    @Parent(key: "dependency_id")
    var dependency: Dependency
    
    @Enum(key: "call_type")
    var callType: CallType
    
    @OptionalField(key: "config")
    var config: [String: AnyCodable]?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, endpointId: UUID, dependencyId: UUID, callType: CallType,
         config: [String: AnyCodable]? = nil) {
        self.id = id
        self.$endpoint.id = endpointId
        self.$dependency.id = dependencyId
        self.callType = callType
        self.config = config
    }
}