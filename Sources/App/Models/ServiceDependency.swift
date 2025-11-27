import Fluent
import Vapor

final class ServiceDependency: Model, Content, @unchecked Sendable {
    static let schema = "service_dependencies"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "service_id")
    var service: Service
    
    @Parent(key: "dependency_id")
    var dependency: Dependency
    
    @Field(key: "environment_code")
    var environmentCode: String?
    
    @Field(key: "config_override")
    var configOverride: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, serviceID: UUID, dependencyID: UUID, environmentCode: String? = nil, configOverride: [String: String] = [:]) {
        self.id = id
        self.$service.id = serviceID
        self.$dependency.id = dependencyID
        self.environmentCode = environmentCode
        self.configOverride = configOverride
    }
}