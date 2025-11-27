import Fluent
import Vapor

final class Dependency: Model, Content, @unchecked Sendable {
    static let schema = "dependencies"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Field(key: "version")
    var version: String
    
    @Enum(key: "dependency_type")
    var dependencyType: DependencyType
    
    @Field(key: "config")
    var config: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, name: String, description: String? = nil, version: String, dependencyType: DependencyType, config: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.dependencyType = dependencyType
        self.config = config
    }
}

enum DependencyType: String, Codable, CaseIterable {
    case DATABASE = "DATABASE"
    case CACHE = "CACHE"
    case QUEUE = "QUEUE"
    case STORAGE = "STORAGE"
    case EXTERNAL_API = "EXTERNAL_API"
    case LIBRARY = "LIBRARY"
}