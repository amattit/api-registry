import Fluent
import Vapor

final class ServiceToServiceDependency: Model, Content, @unchecked Sendable {
    static let schema = "service_to_service_dependencies"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "consumer_service_id")
    var consumerService: Service
    
    @Parent(key: "provider_service_id")
    var providerService: Service
    
    @Field(key: "environment_code")
    var environmentCode: String?
    
    @Field(key: "description")
    var description: String?
    
    @Enum(key: "dependency_type")
    var dependencyType: ServiceDependencyType
    
    @Field(key: "config")
    var config: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, consumerServiceID: UUID, providerServiceID: UUID, environmentCode: String? = nil, description: String? = nil, dependencyType: ServiceDependencyType, config: [String: String] = [:]) {
        self.id = id
        self.$consumerService.id = consumerServiceID
        self.$providerService.id = providerServiceID
        self.environmentCode = environmentCode
        self.description = description
        self.dependencyType = dependencyType
        self.config = config
    }
}

enum ServiceDependencyType: String, Codable, CaseIterable {
    case API_CALL = "API_CALL"
    case EVENT_SUBSCRIPTION = "EVENT_SUBSCRIPTION"
    case DATA_SHARING = "DATA_SHARING"
    case AUTHENTICATION = "AUTHENTICATION"
    case PROXY = "PROXY"
    case LIBRARY_USAGE = "LIBRARY_USAGE"
}