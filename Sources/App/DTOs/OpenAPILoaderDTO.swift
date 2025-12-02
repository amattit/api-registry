import Vapor

struct LoadOpenAPISpecRequest: Content {
    let url: String
    let overwrite: Bool?
    
    init(url: String, overwrite: Bool? = true) {
        self.url = url
        self.overwrite = overwrite
    }
}

struct LoadOpenAPISpecResponse: Content {
    let success: Bool
    let message: String
    let serviceId: UUID?
    let endpointsCreated: Int
    let endpointsUpdated: Int
    
    init(success: Bool, message: String, serviceId: UUID? = nil, endpointsCreated: Int = 0, endpointsUpdated: Int = 0) {
        self.success = success
        self.message = message
        self.serviceId = serviceId
        self.endpointsCreated = endpointsCreated
        self.endpointsUpdated = endpointsUpdated
    }
}

struct OpenAPIInfo: Codable {
    let title: String
    let version: String
    let description: String?
}

struct OpenAPIParameter: Codable {
    let name: String
    let `in`: String
    let description: String?
    let required: Bool?
    let schema: [String: AnyCodable]?
}

struct OpenAPIRequestBody: Codable {
    let content: [String: AnyCodable]?
    let required: Bool?
}

struct OpenAPIResponse: Codable {
    let description: String
    let content: [String: AnyCodable]?
}

struct OpenAPIOperation: Codable {
    let tags: [String]?
    let summary: String?
    let description: String?
    let operationId: String?
    let parameters: [OpenAPIParameter]?
    let requestBody: OpenAPIRequestBody?
    let responses: [String: OpenAPIResponse]?
    let security: [[String: [String]]]?
}

struct OpenAPISpec: Codable {
    let openapi: String
    let info: OpenAPIInfo
    let paths: [String: [String: OpenAPIOperation]]
    let components: [String: AnyCodable]?
    let security: [[String: [String]]]?
}