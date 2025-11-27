import Vapor

struct CreateDatabaseRequest: Content, Validatable {
    let name: String
    let description: String?
    let databaseType: DatabaseType
    let connectionString: String
    let config: [String: String]
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...150))
        validations.add("databaseType", as: DatabaseType.self)
        validations.add("connectionString", as: String.self, is: !.empty)
        validations.add("config", as: [String: String].self)
    }
}

struct UpdateDatabaseRequest: Content, Validatable {
    let name: String?
    let description: String?
    let databaseType: DatabaseType?
    let connectionString: String?
    let config: [String: String]?
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String?.self, is: .nil || (!.empty && .count(...150)), required: false)
        validations.add("connectionString", as: String?.self, is: .nil || !.empty, required: false)
    }
}

struct DatabaseResponse: Content {
    let databaseId: UUID
    let name: String
    let description: String?
    let databaseType: DatabaseType
    let connectionString: String
    let config: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from database: DatabaseInstance) {
        self.databaseId = database.id!
        self.name = database.name
        self.description = database.description
        self.databaseType = database.databaseType
        self.connectionString = database.connectionString
        self.config = database.config
        self.createdAt = database.createdAt
        self.updatedAt = database.updatedAt
    }
}

struct CreateServiceDbLinkRequest: Content, Validatable {
    let databaseId: UUID
    let environmentCode: String?
    let schemaName: String?
    let connectionOverride: [String: String]
    
    static func validations(_ validations: inout Validations) {
        validations.add("databaseId", as: UUID.self)
        validations.add("connectionOverride", as: [String: String].self)
    }
}

struct ServiceDbLinkResponse: Content {
    let serviceDbLinkId: UUID
    let serviceId: UUID
    let database: DatabaseResponse
    let environmentCode: String?
    let schemaName: String?
    let connectionOverride: [String: String]
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from serviceDbLink: ServiceDbLink, database: DatabaseInstance) {
        self.serviceDbLinkId = serviceDbLink.id!
        self.serviceId = serviceDbLink.$service.id
        self.database = DatabaseResponse(from: database)
        self.environmentCode = serviceDbLink.environmentCode
        self.schemaName = serviceDbLink.schemaName
        self.connectionOverride = serviceDbLink.connectionOverride
        self.createdAt = serviceDbLink.createdAt
        self.updatedAt = serviceDbLink.updatedAt
    }
}