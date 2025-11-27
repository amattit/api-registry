import Fluent
import Vapor

enum EndpointMethod: String, Codable, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

final class Endpoint: Model, Content, @unchecked Sendable {
    static let schema = "endpoints"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "service_id")
    var service: Service
    
    @Enum(key: "method")
    var method: EndpointMethod
    
    @Field(key: "path")
    var path: String
    
    @Field(key: "summary")
    var summary: String
    
    @OptionalField(key: "request_schema")
    var requestSchema: [String: AnyCodable]?
    
    @OptionalField(key: "response_schemas")
    var responseSchemas: [String: AnyCodable]?
    
    @OptionalField(key: "auth")
    var auth: [String: AnyCodable]?
    
    @OptionalField(key: "rate_limit")
    var rateLimit: [String: AnyCodable]?
    
    @OptionalField(key: "metadata")
    var metadata: [String: AnyCodable]?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // Relationships
    @Children(for: \.$endpoint)
    var endpointDependencies: [EndpointDependency]
    
    @Children(for: \.$endpoint)
    var endpointDatabases: [EndpointDatabase]
    
    init() { }
    
    init(id: UUID? = nil, serviceId: UUID, method: EndpointMethod, path: String, summary: String,
         requestSchema: [String: AnyCodable]? = nil, responseSchemas: [String: AnyCodable]? = nil,
         auth: [String: AnyCodable]? = nil, rateLimit: [String: AnyCodable]? = nil,
         metadata: [String: AnyCodable]? = nil) {
        self.id = id
        self.$service.id = serviceId
        self.method = method
        self.path = path
        self.summary = summary
        self.requestSchema = requestSchema
        self.responseSchemas = responseSchemas
        self.auth = auth
        self.rateLimit = rateLimit
        self.metadata = metadata
    }
}