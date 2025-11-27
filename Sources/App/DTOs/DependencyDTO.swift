import Vapor

struct CreateDependencyRequest: Content, Validatable {
    let name: String
    let description: String?
    let version: String
    let dependencyType: DependencyType
    let config: [String: String]
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...150))
        validations.add("version", as: String.self, is: !.empty && .count(...50))
        validations.add("dependencyType", as: DependencyType.self)
        validations.add("config", as: [String: String].self)
    }
}

struct UpdateDependencyRequest: Content, Validatable {
    let name: String?
    let description: String?
    let version: String?
    let dependencyType: DependencyType?
    let config: [String: String]?
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String?.self, is: .nil || (!.empty && .count(...150)), required: false)
        validations.add("version", as: String?.self, is: .nil || (!.empty && .count(...50)), required: false)
    }
}

struct DependencyResponse: Content {
    let dependencyId: UUID
    let name: String
    let description: String?
    let version: String
    let dependencyType: DependencyType
    let config: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from dependency: Dependency) {
        self.dependencyId = dependency.id!
        self.name = dependency.name
        self.description = dependency.description
        self.version = dependency.version
        self.dependencyType = dependency.dependencyType
        self.config = dependency.config
        self.createdAt = dependency.createdAt
        self.updatedAt = dependency.updatedAt
    }
}

struct CreateServiceDependencyRequest: Content, Validatable {
    let dependencyId: UUID
    let environmentCode: String?
    let configOverride: [String: String]
    
    static func validations(_ validations: inout Validations) {
        validations.add("dependencyId", as: UUID.self)
        validations.add("configOverride", as: [String: String].self)
    }
}

struct ServiceDependencyResponse: Content {
    let serviceDependencyId: UUID
    let serviceId: UUID
    let dependency: DependencyResponse
    let environmentCode: String?
    let configOverride: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from serviceDependency: ServiceDependency, dependency: Dependency) {
        self.serviceDependencyId = serviceDependency.id!
        self.serviceId = serviceDependency.$service.id
        self.dependency = DependencyResponse(from: dependency)
        self.environmentCode = serviceDependency.environmentCode
        self.configOverride = serviceDependency.configOverride
        self.createdAt = serviceDependency.createdAt
        self.updatedAt = serviceDependency.updatedAt
    }
}