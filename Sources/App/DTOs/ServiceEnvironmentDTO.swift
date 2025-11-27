import Vapor

struct UpsertServiceEnvironmentRequest: Content, Validatable {
    let displayName: String
    let host: String
    let config: EnvironmentConfig?
    let status: EnvironmentStatus
    
    static func validations(_ validations: inout Validations) {
        validations.add("displayName", as: String.self, is: !.empty && .count(...120))
        validations.add("host", as: String.self, is: !.empty && .count(...255))
        validations.add("status", as: EnvironmentStatus.self)
    }
}

struct ServiceEnvironmentResponse: Content {
    let environmentId: UUID
    let serviceId: UUID
    let code: String
    let displayName: String
    let host: String
    let config: EnvironmentConfig?
    let status: EnvironmentStatus
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from environment: ServiceEnvironment) {
        self.environmentId = environment.id!
        self.serviceId = environment.$service.id
        self.code = environment.code
        self.displayName = environment.displayName
        self.host = environment.host
        self.config = environment.config
        self.status = environment.status
        self.createdAt = environment.createdAt
        self.updatedAt = environment.updatedAt
    }
}