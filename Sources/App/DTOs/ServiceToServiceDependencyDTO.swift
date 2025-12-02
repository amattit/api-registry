import Vapor

struct CreateServiceToServiceDependencyRequest: Content, Validatable {
    let providerServiceId: UUID
    let environmentCode: String?
    let description: String?
    let dependencyType: ServiceDependencyType
    let config: [String: String]
    
    static func validations(_ validations: inout Validations) {
        validations.add("providerServiceId", as: UUID.self)
        validations.add("dependencyType", as: ServiceDependencyType.self)
        validations.add("config", as: [String: String].self)
    }
}

struct UpdateServiceToServiceDependencyRequest: Content, Validatable {
    let environmentCode: String?
    let description: String?
    let dependencyType: ServiceDependencyType?
    let config: [String: String]?
    
    static func validations(_ validations: inout Validations) {
        // All fields are optional for update
    }
}

struct ServiceToServiceDependencyResponse: Content {
    let id: UUID
    let consumerService: ServiceSummary
    let providerService: ServiceSummary
    let environmentCode: String?
    let description: String?
    let dependencyType: ServiceDependencyType
    let config: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from dependency: ServiceToServiceDependency, consumerService: Service, providerService: Service) {
        self.id = dependency.id!
        self.consumerService = ServiceSummary(from: consumerService)
        self.providerService = ServiceSummary(from: providerService)
        self.environmentCode = dependency.environmentCode
        self.description = dependency.description
        self.dependencyType = dependency.dependencyType
        self.config = dependency.config
        self.createdAt = dependency.createdAt
        self.updatedAt = dependency.updatedAt
    }
}

struct ServiceSummary: Content {
    let id: UUID
    let name: String
    let description: String?
    let serviceType: ServiceType
    let owner: String
    
    init(from service: Service) {
        self.id = service.id!
        self.name = service.name
        self.description = service.description
        self.serviceType = service.serviceType
        self.owner = service.owner
    }
}

struct ServiceToServiceDependencyGraphResponse: Content {
    let serviceId: UUID
    let serviceName: String
    let dependencies: [ServiceToServiceDependencyResponse]
    let dependents: [ServiceToServiceDependencyResponse]
    
    init(
        service: Service,
        dependencies: [ServiceToServiceDependencyResponse],
        dependents: [ServiceToServiceDependencyResponse]
    ) {
        self.serviceId = service.id!
        self.serviceName = service.name
        self.dependencies = dependencies
        self.dependents = dependents
    }
}
