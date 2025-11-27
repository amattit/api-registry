import Vapor

// MARK: - Request DTOs

struct CreateEndpointRequest: Content, Validatable {
    let method: EndpointMethod
    let path: String
    let summary: String
    let requestSchema: [String: AnyCodable]?
    let responseSchemas: [String: AnyCodable]?
    let auth: [String: AnyCodable]?
    let rateLimit: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?
    let calls: [EndpointCallRequest]?
    let databases: [EndpointDatabaseRequest]?
    
    static func validations(_ validations: inout Validations) {
        validations.add("path", as: String.self, is: !.empty)
        validations.add("summary", as: String.self, is: !.empty)
    }
}

struct UpdateEndpointRequest: Content, Validatable {
    let method: EndpointMethod?
    let path: String?
    let summary: String?
    let requestSchema: [String: AnyCodable]?
    let responseSchemas: [String: AnyCodable]?
    let auth: [String: AnyCodable]?
    let rateLimit: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?
    
    static func validations(_ validations: inout Validations) {
        validations.add("path", as: String?.self, is: .nil || !.empty, required: false)
        validations.add("summary", as: String?.self, is: .nil || !.empty, required: false)
    }
}

struct EndpointCallRequest: Content {
    let dependencyId: UUID
    let callType: CallType
    let config: [String: AnyCodable]?
}

struct EndpointDatabaseRequest: Content {
    let databaseId: UUID
    let operationType: OperationType
    let tableNames: [String]?
    let config: [String: AnyCodable]?
}

// MARK: - Response DTOs

struct EndpointResponse: Content {
    let endpointId: UUID
    let serviceId: UUID
    let method: EndpointMethod
    let path: String
    let summary: String
    let requestSchema: [String: AnyCodable]?
    let responseSchemas: [String: AnyCodable]?
    let auth: [String: AnyCodable]?
    let rateLimit: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?
    let calls: [EndpointCallResponse]?
    let databases: [EndpointDatabaseResponse]?
    let createdAt: Date
    let updatedAt: Date
    
    init(from endpoint: Endpoint, calls: [EndpointCallResponse]? = nil, databases: [EndpointDatabaseResponse]? = nil) {
        self.endpointId = endpoint.id!
        self.serviceId = endpoint.$service.id
        self.method = endpoint.method
        self.path = endpoint.path
        self.summary = endpoint.summary
        self.requestSchema = endpoint.requestSchema
        self.responseSchemas = endpoint.responseSchemas
        self.auth = endpoint.auth
        self.rateLimit = endpoint.rateLimit
        self.metadata = endpoint.metadata
        self.calls = calls
        self.databases = databases
        self.createdAt = endpoint.createdAt!
        self.updatedAt = endpoint.updatedAt!
    }
}

struct EndpointCallResponse: Content {
    let dependencyId: UUID
    let callType: CallType
    let config: [String: AnyCodable]?
    let dependency: DependencyResponse
    
    init(from endpointDependency: EndpointDependency, dependency: Dependency) {
        self.dependencyId = endpointDependency.$dependency.id
        self.callType = endpointDependency.callType
        self.config = endpointDependency.config
        self.dependency = DependencyResponse(from: dependency)
    }
}

struct EndpointDatabaseResponse: Content {
    let databaseId: UUID
    let operationType: OperationType
    let tableNames: [String]?
    let config: [String: AnyCodable]?
    let database: DatabaseResponse
    
    init(from endpointDatabase: EndpointDatabase, database: DatabaseInstance) {
        self.databaseId = endpointDatabase.$database.id
        self.operationType = endpointDatabase.operationType
        self.tableNames = endpointDatabase.tableNames
        self.config = endpointDatabase.config
        self.database = DatabaseResponse(from: database)
    }
}