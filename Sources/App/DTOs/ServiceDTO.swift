import Vapor

struct CreateServiceRequest: Content, Validatable {
    let name: String
    let description: String?
    let owner: String
    let tags: [String]
    let serviceType: ServiceType
    let supportsDatabase: Bool
    let proxy: Bool
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...150))
        validations.add("owner", as: String.self, is: !.empty && .count(...120))
        validations.add("tags", as: [String].self)
        validations.add("serviceType", as: ServiceType.self)
        validations.add("supportsDatabase", as: Bool.self)
        validations.add("proxy", as: Bool.self)
    }
}

struct UpdateServiceRequest: Content, Validatable {
    let name: String?
    let description: String?
    let owner: String?
    let tags: [String]?
    let serviceType: ServiceType?
    let supportsDatabase: Bool?
    let proxy: Bool?
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String?.self, is: .nil || (!.empty && .count(...150)), required: false)
        validations.add("owner", as: String?.self, is: .nil || (!.empty && .count(...120)), required: false)
    }
}

struct ServiceResponse: Content {
    let serviceId: UUID
    let name: String
    let description: String?
    let owner: String
    let tags: [String]
    let serviceType: ServiceType
    let supportsDatabase: Bool
    let proxy: Bool
    let createdAt: Date?
    let updatedAt: Date?
    let environments: [ServiceEnvironmentResponse]?
    
    init(from service: Service, environments: [ServiceEnvironment]? = nil) {
        self.serviceId = service.id!
        self.name = service.name
        self.description = service.description
        self.owner = service.owner
        self.tags = service.tags
        self.serviceType = service.serviceType
        self.supportsDatabase = service.supportsDatabase
        self.proxy = service.proxy
        self.createdAt = service.createdAt
        self.updatedAt = service.updatedAt
        self.environments = environments?.map(ServiceEnvironmentResponse.init)
    }
}