import XCTVapor
@testable import App

final class OpenAPILoaderTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        app = Application(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await app.asyncShutdown()
    }
    
    func testLoadOpenAPISpecFromURL() async throws {
        let testURL = "http://localhost:12001/openapi.json"
        
        let requestBody = LoadOpenAPISpecRequest(url: testURL, overwrite: true)
        
        try await app.test(.POST, "/api/v1/openapi/load") { req in
            try req.content.encode(requestBody)
        } afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(LoadOpenAPISpecResponse.self)
            XCTAssertTrue(response.success)
            XCTAssertNotNil(response.serviceId)
            XCTAssertGreaterThan(response.endpointsCreated, 0)
            XCTAssertEqual(response.message, "OpenAPI specification loaded successfully")
        }
    }
    
    func testLoadOpenAPISpecInvalidURL() async throws {
        let requestBody = LoadOpenAPISpecRequest(url: "invalid-url", overwrite: true)
        
        try await app.test(.POST, "/api/v1/openapi/load") { req in
            try req.content.encode(requestBody)
        } afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
    
    func testGetServiceLoadStatus() async throws {
        // Сначала загружаем спецификацию
        let testURL = "http://localhost:12001/openapi.json"
        let requestBody = LoadOpenAPISpecRequest(url: testURL, overwrite: true)
        
        var serviceId: UUID?
        
        try await app.test(.POST, "/api/v1/openapi/load") { req in
            try req.content.encode(requestBody)
        } afterResponse: { res in
            let response = try res.content.decode(LoadOpenAPISpecResponse.self)
            serviceId = response.serviceId
        }
        
        guard let id = serviceId else {
            XCTFail("Service ID should not be nil")
            return
        }
        
        // Теперь проверяем статус
        try await app.test(.GET, "/api/v1/openapi/status/\(id.uuidString)") { req in
            // No body needed for GET request
        } afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let response = try res.content.decode(ServiceLoadStatusResponse.self)
            XCTAssertEqual(response.serviceId, id)
            XCTAssertEqual(response.serviceName, "api-gateway-composer")
            XCTAssertGreaterThan(response.endpointsCount, 0)
        }
    }
}