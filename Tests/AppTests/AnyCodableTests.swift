@testable import App
import XCTest

final class AnyCodableTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitWithNil() {
        let anyCodable = AnyCodable(nil as String?)
        XCTAssertTrue(anyCodable.value is Void)
    }
    
    func testInitWithBool() {
        let anyCodable = AnyCodable(true)
        XCTAssertEqual(anyCodable.value as? Bool, true)
    }
    
    func testInitWithInt() {
        let anyCodable = AnyCodable(42)
        XCTAssertEqual(anyCodable.value as? Int, 42)
    }
    
    func testInitWithDouble() {
        let anyCodable = AnyCodable(3.14)
        XCTAssertEqual(anyCodable.value as? Double, 3.14)
    }
    
    func testInitWithString() {
        let anyCodable = AnyCodable("hello")
        XCTAssertEqual(anyCodable.value as? String, "hello")
    }
    
    // MARK: - Decoding Tests
    
    func testDecodeNil() throws {
        let json = "null"
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertTrue(anyCodable.value is Void)
    }
    
    func testDecodeBool() throws {
        let json = "true"
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(anyCodable.value as? Bool, true)
    }
    
    func testDecodeInt() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(anyCodable.value as? Int, 42)
    }
    
    func testDecodeDouble() throws {
        let json = "3.14"
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(anyCodable.value as? Double, 3.14)
    }
    
    func testDecodeString() throws {
        let json = "\"hello\""
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(anyCodable.value as? String, "hello")
    }
    
    func testDecodeArray() throws {
        let json = "[1, 2, 3]"
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        let array = anyCodable.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 3)
    }
    
    func testDecodeDictionary() throws {
        let json = "{\"key\": \"value\", \"number\": 42}"
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        let dict = anyCodable.value as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["key"] as? String, "value")
        XCTAssertEqual(dict?["number"] as? Int, 42)
    }
    
    func testDecodeNestedStructure() throws {
        let json = """
        {
            "users": [
                {"name": "John", "age": 30},
                {"name": "Jane", "age": 25}
            ],
            "active": true,
            "count": 2
        }
        """
        let data = json.data(using: .utf8)!
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)
        let dict = anyCodable.value as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["active"] as? Bool, true)
        XCTAssertEqual(dict?["count"] as? Int, 2)
        
        let users = dict?["users"] as? [Any]
        XCTAssertNotNil(users)
        XCTAssertEqual(users?.count, 2)
    }
    
    // MARK: - Encoding Tests
    
    func testEncodeNil() throws {
        let anyCodable = AnyCodable(nil as String?)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "null")
    }
    
    func testEncodeBool() throws {
        let anyCodable = AnyCodable(true)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "true")
    }
    
    func testEncodeInt() throws {
        let anyCodable = AnyCodable(42)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "42")
    }
    
    func testEncodeDouble() throws {
        let anyCodable = AnyCodable(3.14)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "3.14")
    }
    
    func testEncodeString() throws {
        let anyCodable = AnyCodable("hello")
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"hello\"")
    }
    
    func testEncodeArray() throws {
        let anyCodable = AnyCodable([1, 2, 3])
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[1,2,3]")
    }
    
    func testEncodeDictionary() throws {
        let anyCodable = AnyCodable(["key": "value", "number": 42])
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)
        // Note: Dictionary order is not guaranteed, so we check if it contains expected elements
        XCTAssertTrue(json.contains("\"key\":\"value\""))
        XCTAssertTrue(json.contains("\"number\":42"))
    }
    
    func testEncodeUnsupportedType() {
        struct UnsupportedType {}
        let anyCodable = AnyCodable(UnsupportedType())
        
        XCTAssertThrowsError(try JSONEncoder().encode(anyCodable)) { error in
            XCTAssertTrue(error is EncodingError)
        }
    }
    
    // MARK: - Equatable Tests
    
    func testEqualityWithSameTypes() {
        XCTAssertEqual(AnyCodable(42), AnyCodable(42))
        XCTAssertEqual(AnyCodable("hello"), AnyCodable("hello"))
        XCTAssertEqual(AnyCodable(true), AnyCodable(true))
        XCTAssertEqual(AnyCodable(3.14), AnyCodable(3.14))
    }
    
    func testEqualityWithDifferentValues() {
        XCTAssertNotEqual(AnyCodable(42), AnyCodable(43))
        XCTAssertNotEqual(AnyCodable("hello"), AnyCodable("world"))
        XCTAssertNotEqual(AnyCodable(true), AnyCodable(false))
    }
    
    func testEqualityWithDifferentTypes() {
        XCTAssertNotEqual(AnyCodable(42), AnyCodable("42"))
        XCTAssertNotEqual(AnyCodable(1), AnyCodable(1.0))
        XCTAssertNotEqual(AnyCodable(true), AnyCodable(1))
    }
    
    func testEqualityWithNil() {
        let nilValue1 = AnyCodable(nil as String?)
        let nilValue2 = AnyCodable(nil as Int?)
        XCTAssertEqual(nilValue1, nilValue2)
    }
    
    func testEqualityWithArrays() {
        let array1 = AnyCodable([1, 2, 3])
        let array2 = AnyCodable([1, 2, 3])
        let array3 = AnyCodable([1, 2, 4])
        
        XCTAssertEqual(array1, array2)
        XCTAssertNotEqual(array1, array3)
    }
    
    func testEqualityWithDictionaries() {
        let dict1 = AnyCodable(["key": "value", "number": 42])
        let dict2 = AnyCodable(["key": "value", "number": 42])
        let dict3 = AnyCodable(["key": "different", "number": 42])
        
        XCTAssertEqual(dict1, dict2)
        XCTAssertNotEqual(dict1, dict3)
    }
    
    // MARK: - Hashable Tests
    
    func testHashableWithSameValues() {
        let anyCodable1 = AnyCodable(42)
        let anyCodable2 = AnyCodable(42)
        XCTAssertEqual(anyCodable1.hashValue, anyCodable2.hashValue)
    }
    
    func testHashableWithDifferentValues() {
        let anyCodable1 = AnyCodable(42)
        let anyCodable2 = AnyCodable(43)
        XCTAssertNotEqual(anyCodable1.hashValue, anyCodable2.hashValue)
    }
    
    func testHashableWithStrings() {
        let anyCodable1 = AnyCodable("hello")
        let anyCodable2 = AnyCodable("hello")
        let anyCodable3 = AnyCodable("world")
        
        XCTAssertEqual(anyCodable1.hashValue, anyCodable2.hashValue)
        XCTAssertNotEqual(anyCodable1.hashValue, anyCodable3.hashValue)
    }
    
    func testHashableWithBools() {
        let anyCodable1 = AnyCodable(true)
        let anyCodable2 = AnyCodable(true)
        let anyCodable3 = AnyCodable(false)
        
        XCTAssertEqual(anyCodable1.hashValue, anyCodable2.hashValue)
        XCTAssertNotEqual(anyCodable1.hashValue, anyCodable3.hashValue)
    }
    
    func testHashableWithDoubles() {
        let anyCodable1 = AnyCodable(3.14)
        let anyCodable2 = AnyCodable(3.14)
        let anyCodable3 = AnyCodable(2.71)
        
        XCTAssertEqual(anyCodable1.hashValue, anyCodable2.hashValue)
        XCTAssertNotEqual(anyCodable1.hashValue, anyCodable3.hashValue)
    }
    
    // MARK: - Round-trip Tests
    
    func testRoundTripWithComplexData() throws {
        let originalData: [String: Any] = [
            "string": "hello",
            "number": 42,
            "boolean": true,
            "null": NSNull(),
            "array": [1, 2, 3],
            "nested": [
                "inner": "value",
                "count": 10
            ]
        ]
        
        let anyCodable = AnyCodable(originalData)
        let encoded = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
        
        let decodedDict = decoded.value as? [String: Any]
        XCTAssertNotNil(decodedDict)
        XCTAssertEqual(decodedDict?["string"] as? String, "hello")
        XCTAssertEqual(decodedDict?["number"] as? Int, 42)
        XCTAssertEqual(decodedDict?["boolean"] as? Bool, true)
        
        let nestedDict = decodedDict?["nested"] as? [String: Any]
        XCTAssertNotNil(nestedDict)
        XCTAssertEqual(nestedDict?["inner"] as? String, "value")
        XCTAssertEqual(nestedDict?["count"] as? Int, 10)
    }
}