import Fluent
import Vapor

final class Service: Model, Content, @unchecked Sendable {
    static let schema = "services"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Field(key: "owner")
    var owner: String
    
    @Field(key: "tags")
    var tags: [String]
    
    @Enum(key: "service_type")
    var serviceType: ServiceType
    
    @Field(key: "supports_database")
    var supportsDatabase: Bool
    
    @Field(key: "proxy")
    var proxy: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$service)
    var environments: [ServiceEnvironment]
    
    @Children(for: \.$service)
    var serviceDependencies: [ServiceDependency]
    
    @Children(for: \.$service)
    var endpoints: [Endpoint]
    
    @Children(for: \.$consumerService)
    var consumedServices: [ServiceToServiceDependency]
    
    @Children(for: \.$providerService)
    var providedServices: [ServiceToServiceDependency]
    
    init() { }
    
    init(id: UUID? = nil, name: String, description: String? = nil, owner: String, tags: [String] = [], serviceType: ServiceType, supportsDatabase: Bool = false, proxy: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.owner = owner
        self.tags = tags
        self.serviceType = serviceType
        self.supportsDatabase = supportsDatabase
        self.proxy = proxy
    }
}

enum ServiceType: String, Codable, CaseIterable {
    case APPLICATION = "APPLICATION"
    case LIBRARY = "LIBRARY"
    case JOB = "JOB"
    case PROXY = "PROXY"
}