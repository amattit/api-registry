@testable import App
import XCTest

final class ServiceEnvironmentTests: XCTestCase {
    
    // MARK: - ServiceEnvironment Model Tests
    
    func testServiceEnvironmentInitialization() {
        let serviceId = UUID()
        let environmentId = UUID()
        
        let config = EnvironmentConfig(
            timeoutMs: 5000,
            retries: 3,
            downstreamOverrides: ["service1": "override1"]
        )
        
        let environment = ServiceEnvironment(
            id: environmentId,
            serviceID: serviceId,
            code: "prod",
            displayName: "Production",
            host: "prod.example.com",
            config: config,
            status: .ACTIVE
        )
        
        XCTAssertEqual(environment.id, environmentId)
        XCTAssertEqual(environment.$service.id, serviceId)
        XCTAssertEqual(environment.code, "prod")
        XCTAssertEqual(environment.displayName, "Production")
        XCTAssertEqual(environment.host, "prod.example.com")
        XCTAssertNotNil(environment.config)
        XCTAssertEqual(environment.config?.timeoutMs, 5000)
        XCTAssertEqual(environment.config?.retries, 3)
        XCTAssertEqual(environment.config?.downstreamOverrides?["service1"], "override1")
        XCTAssertEqual(environment.status, .ACTIVE)
    }
    
    func testServiceEnvironmentInitializationWithDefaults() {
        let serviceId = UUID()
        
        let environment = ServiceEnvironment(
            serviceID: serviceId,
            code: "dev",
            displayName: "Development",
            host: "dev.example.com"
        )
        
        XCTAssertNil(environment.id)
        XCTAssertEqual(environment.$service.id, serviceId)
        XCTAssertEqual(environment.code, "dev")
        XCTAssertEqual(environment.displayName, "Development")
        XCTAssertEqual(environment.host, "dev.example.com")
        XCTAssertNil(environment.config)
        XCTAssertEqual(environment.status, .ACTIVE) // Default status
    }
    
    func testServiceEnvironmentInitializationWithInactiveStatus() {
        let serviceId = UUID()
        
        let environment = ServiceEnvironment(
            serviceID: serviceId,
            code: "staging",
            displayName: "Staging",
            host: "staging.example.com",
            status: .INACTIVE
        )
        
        XCTAssertEqual(environment.status, .INACTIVE)
    }
    
    func testServiceEnvironmentEmptyConstructor() {
        let environment = ServiceEnvironment()
        
        XCTAssertNil(environment.id)
        // Other properties are not initialized in empty constructor
    }
    
    // MARK: - EnvironmentConfig Tests
    
    func testEnvironmentConfigInitialization() {
        let config = EnvironmentConfig(
            timeoutMs: 10000,
            retries: 5,
            downstreamOverrides: [
                "service1": "override1",
                "service2": "override2"
            ]
        )
        
        XCTAssertEqual(config.timeoutMs, 10000)
        XCTAssertEqual(config.retries, 5)
        XCTAssertNotNil(config.downstreamOverrides)
        XCTAssertEqual(config.downstreamOverrides?.count, 2)
        XCTAssertEqual(config.downstreamOverrides?["service1"], "override1")
        XCTAssertEqual(config.downstreamOverrides?["service2"], "override2")
    }
    
    func testEnvironmentConfigWithNilValues() {
        let config = EnvironmentConfig(
            timeoutMs: nil,
            retries: nil,
            downstreamOverrides: nil
        )
        
        XCTAssertNil(config.timeoutMs)
        XCTAssertNil(config.retries)
        XCTAssertNil(config.downstreamOverrides)
    }
    
    func testEnvironmentConfigWithEmptyOverrides() {
        let config = EnvironmentConfig(
            timeoutMs: 1000,
            retries: 1,
            downstreamOverrides: [:]
        )
        
        XCTAssertEqual(config.timeoutMs, 1000)
        XCTAssertEqual(config.retries, 1)
        XCTAssertNotNil(config.downstreamOverrides)
        XCTAssertTrue(config.downstreamOverrides!.isEmpty)
    }
    
    func testEnvironmentConfigCodable() throws {
        let config = EnvironmentConfig(
            timeoutMs: 2000,
            retries: 2,
            downstreamOverrides: ["test": "value"]
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"timeoutMs\":2000"))
        XCTAssertTrue(json.contains("\"retries\":2"))
        XCTAssertTrue(json.contains("\"test\":\"value\""))
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(EnvironmentConfig.self, from: data)
        
        XCTAssertEqual(decodedConfig.timeoutMs, 2000)
        XCTAssertEqual(decodedConfig.retries, 2)
        XCTAssertEqual(decodedConfig.downstreamOverrides?["test"], "value")
    }
    
    // MARK: - EnvironmentStatus Tests
    
    func testEnvironmentStatusRawValues() {
        XCTAssertEqual(EnvironmentStatus.ACTIVE.rawValue, "ACTIVE")
        XCTAssertEqual(EnvironmentStatus.INACTIVE.rawValue, "INACTIVE")
    }
    
    func testEnvironmentStatusFromRawValue() {
        XCTAssertEqual(EnvironmentStatus(rawValue: "ACTIVE"), .ACTIVE)
        XCTAssertEqual(EnvironmentStatus(rawValue: "INACTIVE"), .INACTIVE)
    }
    
    func testEnvironmentStatusInvalidRawValue() {
        XCTAssertNil(EnvironmentStatus(rawValue: "INVALID"))
        XCTAssertNil(EnvironmentStatus(rawValue: "active"))
        XCTAssertNil(EnvironmentStatus(rawValue: ""))
    }
    
    func testEnvironmentStatusCaseIterable() {
        let allCases = EnvironmentStatus.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.ACTIVE))
        XCTAssertTrue(allCases.contains(.INACTIVE))
    }
    
    func testEnvironmentStatusCodable() throws {
        // Test encoding
        let encoder = JSONEncoder()
        let activeData = try encoder.encode(EnvironmentStatus.ACTIVE)
        let activeJson = String(data: activeData, encoding: .utf8)
        XCTAssertEqual(activeJson, "\"ACTIVE\"")
        
        let inactiveData = try encoder.encode(EnvironmentStatus.INACTIVE)
        let inactiveJson = String(data: inactiveData, encoding: .utf8)
        XCTAssertEqual(inactiveJson, "\"INACTIVE\"")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedActive = try decoder.decode(EnvironmentStatus.self, from: "\"ACTIVE\"".data(using: .utf8)!)
        XCTAssertEqual(decodedActive, .ACTIVE)
        
        let decodedInactive = try decoder.decode(EnvironmentStatus.self, from: "\"INACTIVE\"".data(using: .utf8)!)
        XCTAssertEqual(decodedInactive, .INACTIVE)
    }
    
    func testEnvironmentStatusEquality() {
        XCTAssertEqual(EnvironmentStatus.ACTIVE, EnvironmentStatus.ACTIVE)
        XCTAssertEqual(EnvironmentStatus.INACTIVE, EnvironmentStatus.INACTIVE)
        XCTAssertNotEqual(EnvironmentStatus.ACTIVE, EnvironmentStatus.INACTIVE)
    }
    
    // MARK: - UpsertServiceEnvironmentRequest Tests
    
    func testUpsertServiceEnvironmentRequestInitialization() {
        let config = EnvironmentConfig(
            timeoutMs: 3000,
            retries: 2,
            downstreamOverrides: ["service": "override"]
        )
        
        let request = UpsertServiceEnvironmentRequest(
            displayName: "Test Environment",
            host: "test.example.com",
            config: config,
            status: .ACTIVE
        )
        
        XCTAssertEqual(request.displayName, "Test Environment")
        XCTAssertEqual(request.host, "test.example.com")
        XCTAssertNotNil(request.config)
        XCTAssertEqual(request.config?.timeoutMs, 3000)
        XCTAssertEqual(request.status, .ACTIVE)
    }
    
    func testUpsertServiceEnvironmentRequestWithNilConfig() {
        let request = UpsertServiceEnvironmentRequest(
            displayName: "Simple Environment",
            host: "simple.example.com",
            config: nil,
            status: .INACTIVE
        )
        
        XCTAssertEqual(request.displayName, "Simple Environment")
        XCTAssertEqual(request.host, "simple.example.com")
        XCTAssertNil(request.config)
        XCTAssertEqual(request.status, .INACTIVE)
    }
    
    // MARK: - ServiceEnvironmentResponse Tests
    
    func testServiceEnvironmentResponseFromEnvironment() {
        let environmentId = UUID()
        let serviceId = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        
        let config = EnvironmentConfig(
            timeoutMs: 4000,
            retries: 3,
            downstreamOverrides: ["downstream": "value"]
        )
        
        let environment = ServiceEnvironment(
            id: environmentId,
            serviceID: serviceId,
            code: "test",
            displayName: "Test Environment",
            host: "test.example.com",
            config: config,
            status: .ACTIVE
        )
        environment.createdAt = createdAt
        environment.updatedAt = updatedAt
        
        let response = ServiceEnvironmentResponse(from: environment)
        
        XCTAssertEqual(response.environmentId, environmentId)
        XCTAssertEqual(response.serviceId, serviceId)
        XCTAssertEqual(response.code, "test")
        XCTAssertEqual(response.displayName, "Test Environment")
        XCTAssertEqual(response.host, "test.example.com")
        XCTAssertNotNil(response.config)
        XCTAssertEqual(response.config?.timeoutMs, 4000)
        XCTAssertEqual(response.config?.retries, 3)
        XCTAssertEqual(response.config?.downstreamOverrides?["downstream"], "value")
        XCTAssertEqual(response.status, .ACTIVE)
        XCTAssertEqual(response.createdAt, createdAt)
        XCTAssertEqual(response.updatedAt, updatedAt)
    }
    
    func testServiceEnvironmentResponseFromEnvironmentWithNilConfig() {
        let environmentId = UUID()
        let serviceId = UUID()
        
        let environment = ServiceEnvironment(
            id: environmentId,
            serviceID: serviceId,
            code: "minimal",
            displayName: "Minimal Environment",
            host: "minimal.example.com",
            config: nil,
            status: .INACTIVE
        )
        
        let response = ServiceEnvironmentResponse(from: environment)
        
        XCTAssertEqual(response.environmentId, environmentId)
        XCTAssertEqual(response.serviceId, serviceId)
        XCTAssertEqual(response.code, "minimal")
        XCTAssertEqual(response.displayName, "Minimal Environment")
        XCTAssertEqual(response.host, "minimal.example.com")
        XCTAssertNil(response.config)
        XCTAssertEqual(response.status, .INACTIVE)
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testUpsertServiceEnvironmentRequestJSONDecoding() throws {
        let json = """
        {
            "displayName": "JSON Environment",
            "host": "json.example.com",
            "config": {
                "timeoutMs": 5000,
                "retries": 4,
                "downstreamOverrides": {
                    "service1": "override1",
                    "service2": "override2"
                }
            },
            "status": "ACTIVE"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(UpsertServiceEnvironmentRequest.self, from: data)
        
        XCTAssertEqual(request.displayName, "JSON Environment")
        XCTAssertEqual(request.host, "json.example.com")
        XCTAssertNotNil(request.config)
        XCTAssertEqual(request.config?.timeoutMs, 5000)
        XCTAssertEqual(request.config?.retries, 4)
        XCTAssertEqual(request.config?.downstreamOverrides?.count, 2)
        XCTAssertEqual(request.status, .ACTIVE)
    }
    
    func testUpsertServiceEnvironmentRequestJSONDecodingWithNullConfig() throws {
        let json = """
        {
            "displayName": "No Config Environment",
            "host": "noconfig.example.com",
            "config": null,
            "status": "INACTIVE"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(UpsertServiceEnvironmentRequest.self, from: data)
        
        XCTAssertEqual(request.displayName, "No Config Environment")
        XCTAssertEqual(request.host, "noconfig.example.com")
        XCTAssertNil(request.config)
        XCTAssertEqual(request.status, .INACTIVE)
    }
    
    func testServiceEnvironmentResponseJSONEncoding() throws {
        let environmentId = UUID()
        let serviceId = UUID()
        
        let config = EnvironmentConfig(
            timeoutMs: 6000,
            retries: 5,
            downstreamOverrides: ["test": "encode"]
        )
        
        let environment = ServiceEnvironment(
            id: environmentId,
            serviceID: serviceId,
            code: "encode",
            displayName: "Encode Environment",
            host: "encode.example.com",
            config: config,
            status: .ACTIVE
        )
        
        let response = ServiceEnvironmentResponse(from: environment)
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"code\":\"encode\""))
        XCTAssertTrue(json.contains("\"displayName\":\"Encode Environment\""))
        XCTAssertTrue(json.contains("\"host\":\"encode.example.com\""))
        XCTAssertTrue(json.contains("\"status\":\"ACTIVE\""))
        XCTAssertTrue(json.contains("\"timeoutMs\":6000"))
        XCTAssertTrue(json.contains("\"retries\":5"))
    }
}