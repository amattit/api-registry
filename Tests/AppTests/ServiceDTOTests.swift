@testable import App
import XCTest
import Vapor

final class ServiceDTOTests: XCTestCase {
    
    // MARK: - CreateServiceRequest Tests
    
    func testCreateServiceRequestInitialization() {
        let request = CreateServiceRequest(
            name: "Test Service",
            description: "A test service",
            owner: "test-owner",
            tags: ["api", "test"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false
        )
        
        XCTAssertEqual(request.name, "Test Service")
        XCTAssertEqual(request.description, "A test service")
        XCTAssertEqual(request.owner, "test-owner")
        XCTAssertEqual(request.tags, ["api", "test"])
        XCTAssertEqual(request.serviceType, .APPLICATION)
        XCTAssertEqual(request.supportsDatabase, true)
        XCTAssertEqual(request.proxy, false)
    }
    
    func testCreateServiceRequestWithNilDescription() {
        let request = CreateServiceRequest(
            name: "Service",
            description: nil,
            owner: "owner",
            tags: [],
            serviceType: .LIBRARY,
            supportsDatabase: false,
            proxy: false
        )
        
        XCTAssertNil(request.description)
    }
    
    func testCreateServiceRequestWithEmptyTags() {
        let request = CreateServiceRequest(
            name: "Service",
            description: nil,
            owner: "owner",
            tags: [],
            serviceType: .JOB,
            supportsDatabase: false,
            proxy: false
        )
        
        XCTAssertEqual(request.tags, [])
        XCTAssertTrue(request.tags.isEmpty)
    }
    
    func testCreateServiceRequestWithMultipleTags() {
        let tags = ["microservice", "api", "production", "v2"]
        let request = CreateServiceRequest(
            name: "Tagged Service",
            description: nil,
            owner: "owner",
            tags: tags,
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: true
        )
        
        XCTAssertEqual(request.tags, tags)
        XCTAssertEqual(request.tags.count, 4)
    }
    
    func testCreateServiceRequestAllServiceTypes() {
        let applicationRequest = CreateServiceRequest(
            name: "App", description: nil, owner: "owner", tags: [],
            serviceType: .APPLICATION, supportsDatabase: false, proxy: false
        )
        XCTAssertEqual(applicationRequest.serviceType, .APPLICATION)
        
        let libraryRequest = CreateServiceRequest(
            name: "Lib", description: nil, owner: "owner", tags: [],
            serviceType: .LIBRARY, supportsDatabase: false, proxy: false
        )
        XCTAssertEqual(libraryRequest.serviceType, .LIBRARY)
        
        let jobRequest = CreateServiceRequest(
            name: "Job", description: nil, owner: "owner", tags: [],
            serviceType: .JOB, supportsDatabase: false, proxy: false
        )
        XCTAssertEqual(jobRequest.serviceType, .JOB)
        
        let proxyRequest = CreateServiceRequest(
            name: "Proxy", description: nil, owner: "owner", tags: [],
            serviceType: .PROXY, supportsDatabase: false, proxy: true
        )
        XCTAssertEqual(proxyRequest.serviceType, .PROXY)
    }
    
    // MARK: - UpdateServiceRequest Tests
    
    func testUpdateServiceRequestWithAllFields() {
        let request = UpdateServiceRequest(
            name: "Updated Service",
            description: "Updated description",
            owner: "new-owner",
            tags: ["updated", "tags"],
            serviceType: .LIBRARY,
            supportsDatabase: true,
            proxy: true
        )
        
        XCTAssertEqual(request.name, "Updated Service")
        XCTAssertEqual(request.description, "Updated description")
        XCTAssertEqual(request.owner, "new-owner")
        XCTAssertEqual(request.tags, ["updated", "tags"])
        XCTAssertEqual(request.serviceType, .LIBRARY)
        XCTAssertEqual(request.supportsDatabase, true)
        XCTAssertEqual(request.proxy, true)
    }
    
    func testUpdateServiceRequestWithNilFields() {
        let request = UpdateServiceRequest(
            name: nil,
            description: nil,
            owner: nil,
            tags: nil,
            serviceType: nil,
            supportsDatabase: nil,
            proxy: nil
        )
        
        XCTAssertNil(request.name)
        XCTAssertNil(request.description)
        XCTAssertNil(request.owner)
        XCTAssertNil(request.tags)
        XCTAssertNil(request.serviceType)
        XCTAssertNil(request.supportsDatabase)
        XCTAssertNil(request.proxy)
    }
    
    func testUpdateServiceRequestPartialUpdate() {
        let request = UpdateServiceRequest(
            name: "New Name",
            description: nil,
            owner: "new-owner",
            tags: nil,
            serviceType: .PROXY,
            supportsDatabase: nil,
            proxy: nil
        )
        
        XCTAssertEqual(request.name, "New Name")
        XCTAssertNil(request.description)
        XCTAssertEqual(request.owner, "new-owner")
        XCTAssertNil(request.tags)
        XCTAssertEqual(request.serviceType, .PROXY)
        XCTAssertNil(request.supportsDatabase)
        XCTAssertNil(request.proxy)
    }
    
    // MARK: - ServiceResponse Tests
    
    func testServiceResponseFromService() {
        let serviceId = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        
        let service = Service(
            id: serviceId,
            name: "Response Service",
            description: "Service for response",
            owner: "response-owner",
            tags: ["response", "test"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false
        )
        service.createdAt = createdAt
        service.updatedAt = updatedAt
        
        let response = ServiceResponse(from: service)
        
        XCTAssertEqual(response.serviceId, serviceId)
        XCTAssertEqual(response.name, "Response Service")
        XCTAssertEqual(response.description, "Service for response")
        XCTAssertEqual(response.owner, "response-owner")
        XCTAssertEqual(response.tags, ["response", "test"])
        XCTAssertEqual(response.serviceType, .APPLICATION)
        XCTAssertEqual(response.supportsDatabase, true)
        XCTAssertEqual(response.proxy, false)
        XCTAssertEqual(response.createdAt, createdAt)
        XCTAssertEqual(response.updatedAt, updatedAt)
        XCTAssertNil(response.environments)
    }
    
    func testServiceResponseFromServiceWithNilDescription() {
        let serviceId = UUID()
        let service = Service(
            id: serviceId,
            name: "No Description Service",
            description: nil,
            owner: "owner",
            tags: [],
            serviceType: .LIBRARY,
            supportsDatabase: false,
            proxy: false
        )
        
        let response = ServiceResponse(from: service)
        
        XCTAssertEqual(response.serviceId, serviceId)
        XCTAssertEqual(response.name, "No Description Service")
        XCTAssertNil(response.description)
        XCTAssertEqual(response.owner, "owner")
        XCTAssertEqual(response.tags, [])
        XCTAssertEqual(response.serviceType, .LIBRARY)
        XCTAssertEqual(response.supportsDatabase, false)
        XCTAssertEqual(response.proxy, false)
    }
    
    func testServiceResponseFromServiceWithEnvironments() {
        let serviceId = UUID()
        let service = Service(
            id: serviceId,
            name: "Service With Envs",
            owner: "owner",
            serviceType: .APPLICATION
        )
        
        let env1 = ServiceEnvironment(
            id: UUID(),
            serviceID: serviceId,
            code: "dev",
            displayName: "Development",
            host: "dev.example.com",
            status: .ACTIVE
        )
        
        let env2 = ServiceEnvironment(
            id: UUID(),
            serviceID: serviceId,
            code: "prod",
            displayName: "Production",
            host: "prod.example.com",
            status: .ACTIVE
        )
        
        let response = ServiceResponse(from: service, environments: [env1, env2])
        
        XCTAssertEqual(response.serviceId, serviceId)
        XCTAssertNotNil(response.environments)
        XCTAssertEqual(response.environments?.count, 2)
        
        let envResponses = response.environments!
        XCTAssertEqual(envResponses[0].code, "dev")
        XCTAssertEqual(envResponses[0].displayName, "Development")
        XCTAssertEqual(envResponses[1].code, "prod")
        XCTAssertEqual(envResponses[1].displayName, "Production")
    }
    
    func testServiceResponseFromServiceWithEmptyEnvironments() {
        let serviceId = UUID()
        let service = Service(
            id: serviceId,
            name: "Service No Envs",
            owner: "owner",
            serviceType: .JOB
        )
        
        let response = ServiceResponse(from: service, environments: [])
        
        XCTAssertNotNil(response.environments)
        XCTAssertEqual(response.environments?.count, 0)
        XCTAssertTrue(response.environments!.isEmpty)
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testCreateServiceRequestJSONDecoding() throws {
        let json = """
        {
            "name": "JSON Service",
            "description": "From JSON",
            "owner": "json-owner",
            "tags": ["json", "test"],
            "serviceType": "APPLICATION",
            "supportsDatabase": true,
            "proxy": false
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(CreateServiceRequest.self, from: data)
        
        XCTAssertEqual(request.name, "JSON Service")
        XCTAssertEqual(request.description, "From JSON")
        XCTAssertEqual(request.owner, "json-owner")
        XCTAssertEqual(request.tags, ["json", "test"])
        XCTAssertEqual(request.serviceType, .APPLICATION)
        XCTAssertEqual(request.supportsDatabase, true)
        XCTAssertEqual(request.proxy, false)
    }
    
    func testCreateServiceRequestJSONDecodingWithNullDescription() throws {
        let json = """
        {
            "name": "JSON Service",
            "description": null,
            "owner": "json-owner",
            "tags": [],
            "serviceType": "LIBRARY",
            "supportsDatabase": false,
            "proxy": false
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(CreateServiceRequest.self, from: data)
        
        XCTAssertEqual(request.name, "JSON Service")
        XCTAssertNil(request.description)
        XCTAssertEqual(request.serviceType, .LIBRARY)
    }
    
    func testUpdateServiceRequestJSONDecoding() throws {
        let json = """
        {
            "name": "Updated JSON Service",
            "owner": "updated-owner",
            "serviceType": "PROXY"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(UpdateServiceRequest.self, from: data)
        
        XCTAssertEqual(request.name, "Updated JSON Service")
        XCTAssertNil(request.description)
        XCTAssertEqual(request.owner, "updated-owner")
        XCTAssertNil(request.tags)
        XCTAssertEqual(request.serviceType, .PROXY)
        XCTAssertNil(request.supportsDatabase)
        XCTAssertNil(request.proxy)
    }
    
    func testServiceResponseJSONEncoding() throws {
        let serviceId = UUID()
        let service = Service(
            id: serviceId,
            name: "Encode Service",
            description: "For encoding",
            owner: "encode-owner",
            tags: ["encode"],
            serviceType: .JOB,
            supportsDatabase: false,
            proxy: false
        )
        
        let response = ServiceResponse(from: service)
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"name\":\"Encode Service\""))
        XCTAssertTrue(json.contains("\"description\":\"For encoding\""))
        XCTAssertTrue(json.contains("\"owner\":\"encode-owner\""))
        XCTAssertTrue(json.contains("\"serviceType\":\"JOB\""))
        XCTAssertTrue(json.contains("\"supportsDatabase\":false"))
        XCTAssertTrue(json.contains("\"proxy\":false"))
    }
}