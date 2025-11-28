@testable import App
import XCTest

final class ServiceTests: XCTestCase {
    
    // MARK: - Service Initialization Tests
    
    func testServiceInitWithAllParameters() {
        let id = UUID()
        let service = Service(
            id: id,
            name: "Test Service",
            description: "A test service",
            owner: "test-owner",
            tags: ["api", "test"],
            serviceType: .APPLICATION,
            supportsDatabase: true,
            proxy: false
        )
        
        XCTAssertEqual(service.id, id)
        XCTAssertEqual(service.name, "Test Service")
        XCTAssertEqual(service.description, "A test service")
        XCTAssertEqual(service.owner, "test-owner")
        XCTAssertEqual(service.tags, ["api", "test"])
        XCTAssertEqual(service.serviceType, .APPLICATION)
        XCTAssertEqual(service.supportsDatabase, true)
        XCTAssertEqual(service.proxy, false)
    }
    
    func testServiceInitWithMinimalParameters() {
        let service = Service(
            name: "Minimal Service",
            owner: "owner",
            serviceType: .LIBRARY
        )
        
        XCTAssertNil(service.id)
        XCTAssertEqual(service.name, "Minimal Service")
        XCTAssertNil(service.description)
        XCTAssertEqual(service.owner, "owner")
        XCTAssertEqual(service.tags, [])
        XCTAssertEqual(service.serviceType, .LIBRARY)
        XCTAssertEqual(service.supportsDatabase, false)
        XCTAssertEqual(service.proxy, false)
    }
    
    func testServiceInitWithDefaultValues() {
        let service = Service(
            name: "Default Service",
            owner: "owner",
            serviceType: .JOB
        )
        
        XCTAssertEqual(service.tags, [])
        XCTAssertEqual(service.supportsDatabase, false)
        XCTAssertEqual(service.proxy, false)
    }
    
    func testServiceInitWithEmptyConstructor() {
        let service = Service()
        
        XCTAssertNil(service.id)
        // Note: Other properties are not initialized in the empty constructor
        // This is typical for Fluent models
    }
    
    func testServiceWithDatabaseSupport() {
        let service = Service(
            name: "Database Service",
            owner: "db-owner",
            serviceType: .APPLICATION,
            supportsDatabase: true
        )
        
        XCTAssertEqual(service.supportsDatabase, true)
    }
    
    func testServiceWithProxy() {
        let service = Service(
            name: "Proxy Service",
            owner: "proxy-owner",
            serviceType: .PROXY,
            proxy: true
        )
        
        XCTAssertEqual(service.proxy, true)
        XCTAssertEqual(service.serviceType, .PROXY)
    }
    
    func testServiceWithMultipleTags() {
        let tags = ["api", "microservice", "production", "v1"]
        let service = Service(
            name: "Tagged Service",
            owner: "tag-owner",
            tags: tags,
            serviceType: .APPLICATION
        )
        
        XCTAssertEqual(service.tags, tags)
        XCTAssertEqual(service.tags.count, 4)
        XCTAssertTrue(service.tags.contains("api"))
        XCTAssertTrue(service.tags.contains("microservice"))
        XCTAssertTrue(service.tags.contains("production"))
        XCTAssertTrue(service.tags.contains("v1"))
    }
    
    func testServiceWithEmptyTags() {
        let service = Service(
            name: "No Tags Service",
            owner: "owner",
            serviceType: .LIBRARY,
            tags: []
        )
        
        XCTAssertEqual(service.tags, [])
        XCTAssertTrue(service.tags.isEmpty)
    }
    
    func testServiceWithLongDescription() {
        let longDescription = """
        This is a very long description that spans multiple lines.
        It contains detailed information about the service functionality,
        its purpose, and how it should be used in the system.
        """
        
        let service = Service(
            name: "Documented Service",
            description: longDescription,
            owner: "doc-owner",
            serviceType: .APPLICATION
        )
        
        XCTAssertEqual(service.description, longDescription)
    }
    
    func testServiceWithNilDescription() {
        let service = Service(
            name: "Undocumented Service",
            description: nil,
            owner: "owner",
            serviceType: .JOB
        )
        
        XCTAssertNil(service.description)
    }
}

// MARK: - ServiceType Tests

final class ServiceTypeTests: XCTestCase {
    
    func testServiceTypeRawValues() {
        XCTAssertEqual(ServiceType.APPLICATION.rawValue, "APPLICATION")
        XCTAssertEqual(ServiceType.LIBRARY.rawValue, "LIBRARY")
        XCTAssertEqual(ServiceType.JOB.rawValue, "JOB")
        XCTAssertEqual(ServiceType.PROXY.rawValue, "PROXY")
    }
    
    func testServiceTypeFromRawValue() {
        XCTAssertEqual(ServiceType(rawValue: "APPLICATION"), .APPLICATION)
        XCTAssertEqual(ServiceType(rawValue: "LIBRARY"), .LIBRARY)
        XCTAssertEqual(ServiceType(rawValue: "JOB"), .JOB)
        XCTAssertEqual(ServiceType(rawValue: "PROXY"), .PROXY)
    }
    
    func testServiceTypeInvalidRawValue() {
        XCTAssertNil(ServiceType(rawValue: "INVALID"))
        XCTAssertNil(ServiceType(rawValue: "application"))
        XCTAssertNil(ServiceType(rawValue: ""))
    }
    
    func testServiceTypeCaseIterable() {
        let allCases = ServiceType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.APPLICATION))
        XCTAssertTrue(allCases.contains(.LIBRARY))
        XCTAssertTrue(allCases.contains(.JOB))
        XCTAssertTrue(allCases.contains(.PROXY))
    }
    
    func testServiceTypeCodable() throws {
        // Test encoding
        let encoder = JSONEncoder()
        let applicationData = try encoder.encode(ServiceType.APPLICATION)
        let applicationJson = String(data: applicationData, encoding: .utf8)
        XCTAssertEqual(applicationJson, "\"APPLICATION\"")
        
        let libraryData = try encoder.encode(ServiceType.LIBRARY)
        let libraryJson = String(data: libraryData, encoding: .utf8)
        XCTAssertEqual(libraryJson, "\"LIBRARY\"")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedApplication = try decoder.decode(ServiceType.self, from: "\"APPLICATION\"".data(using: .utf8)!)
        XCTAssertEqual(decodedApplication, .APPLICATION)
        
        let decodedJob = try decoder.decode(ServiceType.self, from: "\"JOB\"".data(using: .utf8)!)
        XCTAssertEqual(decodedJob, .JOB)
    }
    
    func testServiceTypeDecodingInvalidValue() {
        let decoder = JSONDecoder()
        let invalidJson = "\"INVALID_TYPE\"".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(ServiceType.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testServiceTypeEquality() {
        XCTAssertEqual(ServiceType.APPLICATION, ServiceType.APPLICATION)
        XCTAssertNotEqual(ServiceType.APPLICATION, ServiceType.LIBRARY)
        XCTAssertNotEqual(ServiceType.JOB, ServiceType.PROXY)
    }
    
    func testServiceTypeInService() {
        let applicationService = Service(
            name: "App Service",
            owner: "owner",
            serviceType: .APPLICATION
        )
        
        let libraryService = Service(
            name: "Lib Service",
            owner: "owner",
            serviceType: .LIBRARY
        )
        
        XCTAssertEqual(applicationService.serviceType, .APPLICATION)
        XCTAssertEqual(libraryService.serviceType, .LIBRARY)
        XCTAssertNotEqual(applicationService.serviceType, libraryService.serviceType)
    }
}