@testable import App
import XCTest

final class DatabaseTests: XCTestCase {
    
    // MARK: - DatabaseInstance Model Tests
    
    func testDatabaseInstanceInitialization() {
        let databaseId = UUID()
        let config = [
            "max_connections": "100",
            "timeout": "30",
            "ssl_mode": "require"
        ]
        
        let database = DatabaseInstance(
            id: databaseId,
            name: "Production DB",
            description: "Main production database",
            databaseType: .POSTGRESQL,
            connectionString: "postgresql://user:pass@localhost:5432/db",
            config: config
        )
        
        XCTAssertEqual(database.id, databaseId)
        XCTAssertEqual(database.name, "Production DB")
        XCTAssertEqual(database.description, "Main production database")
        XCTAssertEqual(database.databaseType, .POSTGRESQL)
        XCTAssertEqual(database.connectionString, "postgresql://user:pass@localhost:5432/db")
        XCTAssertEqual(database.config, config)
        XCTAssertEqual(database.config["max_connections"], "100")
        XCTAssertEqual(database.config["timeout"], "30")
        XCTAssertEqual(database.config["ssl_mode"], "require")
    }
    
    func testDatabaseInstanceInitializationWithDefaults() {
        let database = DatabaseInstance(
            name: "Test DB",
            databaseType: .MYSQL,
            connectionString: "mysql://localhost:3306/test"
        )
        
        XCTAssertNil(database.id)
        XCTAssertEqual(database.name, "Test DB")
        XCTAssertNil(database.description)
        XCTAssertEqual(database.databaseType, .MYSQL)
        XCTAssertEqual(database.connectionString, "mysql://localhost:3306/test")
        XCTAssertEqual(database.config, [:])
        XCTAssertTrue(database.config.isEmpty)
    }
    
    func testDatabaseInstanceWithNilDescription() {
        let database = DatabaseInstance(
            name: "No Description DB",
            description: nil,
            databaseType: .MONGODB,
            connectionString: "mongodb://localhost:27017/test"
        )
        
        XCTAssertNil(database.description)
    }
    
    func testDatabaseInstanceWithEmptyConfig() {
        let database = DatabaseInstance(
            name: "Simple DB",
            databaseType: .SQLITE,
            connectionString: "sqlite:///path/to/db.sqlite",
            config: [:]
        )
        
        XCTAssertEqual(database.config, [:])
        XCTAssertTrue(database.config.isEmpty)
    }
    
    func testDatabaseInstanceWithComplexConfig() {
        let config = [
            "host": "db.example.com",
            "port": "5432",
            "database": "production",
            "username": "app_user",
            "ssl_mode": "require",
            "connection_timeout": "30",
            "max_connections": "200",
            "min_connections": "10",
            "idle_timeout": "600",
            "charset": "utf8mb4"
        ]
        
        let database = DatabaseInstance(
            name: "Complex DB",
            description: "Database with complex configuration",
            databaseType: .POSTGRESQL,
            connectionString: "postgresql://app_user:password@db.example.com:5432/production",
            config: config
        )
        
        XCTAssertEqual(database.config.count, 10)
        XCTAssertEqual(database.config["host"], "db.example.com")
        XCTAssertEqual(database.config["port"], "5432")
        XCTAssertEqual(database.config["max_connections"], "200")
        XCTAssertEqual(database.config["charset"], "utf8mb4")
    }
    
    func testDatabaseInstanceEmptyConstructor() {
        let database = DatabaseInstance()
        
        XCTAssertNil(database.id)
        // Other properties are not initialized in empty constructor
    }
    
    // MARK: - DatabaseType Tests
    
    func testDatabaseTypeRawValues() {
        XCTAssertEqual(DatabaseType.POSTGRESQL.rawValue, "POSTGRESQL")
        XCTAssertEqual(DatabaseType.MYSQL.rawValue, "MYSQL")
        XCTAssertEqual(DatabaseType.MONGODB.rawValue, "MONGODB")
        XCTAssertEqual(DatabaseType.REDIS.rawValue, "REDIS")
        XCTAssertEqual(DatabaseType.ELASTICSEARCH.rawValue, "ELASTICSEARCH")
        XCTAssertEqual(DatabaseType.CASSANDRA.rawValue, "CASSANDRA")
        XCTAssertEqual(DatabaseType.SQLITE.rawValue, "SQLITE")
        XCTAssertEqual(DatabaseType.ORACLE.rawValue, "ORACLE")
        XCTAssertEqual(DatabaseType.MSSQL.rawValue, "MSSQL")
    }
    
    func testDatabaseTypeFromRawValue() {
        XCTAssertEqual(DatabaseType(rawValue: "POSTGRESQL"), .POSTGRESQL)
        XCTAssertEqual(DatabaseType(rawValue: "MYSQL"), .MYSQL)
        XCTAssertEqual(DatabaseType(rawValue: "MONGODB"), .MONGODB)
        XCTAssertEqual(DatabaseType(rawValue: "REDIS"), .REDIS)
        XCTAssertEqual(DatabaseType(rawValue: "ELASTICSEARCH"), .ELASTICSEARCH)
        XCTAssertEqual(DatabaseType(rawValue: "CASSANDRA"), .CASSANDRA)
        XCTAssertEqual(DatabaseType(rawValue: "SQLITE"), .SQLITE)
        XCTAssertEqual(DatabaseType(rawValue: "ORACLE"), .ORACLE)
        XCTAssertEqual(DatabaseType(rawValue: "MSSQL"), .MSSQL)
    }
    
    func testDatabaseTypeInvalidRawValue() {
        XCTAssertNil(DatabaseType(rawValue: "INVALID"))
        XCTAssertNil(DatabaseType(rawValue: "postgresql"))
        XCTAssertNil(DatabaseType(rawValue: "MySQL"))
        XCTAssertNil(DatabaseType(rawValue: ""))
        XCTAssertNil(DatabaseType(rawValue: "POSTGRES"))
    }
    
    func testDatabaseTypeCaseIterable() {
        let allCases = DatabaseType.allCases
        XCTAssertEqual(allCases.count, 9)
        XCTAssertTrue(allCases.contains(.POSTGRESQL))
        XCTAssertTrue(allCases.contains(.MYSQL))
        XCTAssertTrue(allCases.contains(.MONGODB))
        XCTAssertTrue(allCases.contains(.REDIS))
        XCTAssertTrue(allCases.contains(.ELASTICSEARCH))
        XCTAssertTrue(allCases.contains(.CASSANDRA))
        XCTAssertTrue(allCases.contains(.SQLITE))
        XCTAssertTrue(allCases.contains(.ORACLE))
        XCTAssertTrue(allCases.contains(.MSSQL))
    }
    
    func testDatabaseTypeCodable() throws {
        // Test encoding
        let encoder = JSONEncoder()
        let postgresData = try encoder.encode(DatabaseType.POSTGRESQL)
        let postgresJson = String(data: postgresData, encoding: .utf8)
        XCTAssertEqual(postgresJson, "\"POSTGRESQL\"")
        
        let mongoData = try encoder.encode(DatabaseType.MONGODB)
        let mongoJson = String(data: mongoData, encoding: .utf8)
        XCTAssertEqual(mongoJson, "\"MONGODB\"")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedPostgres = try decoder.decode(DatabaseType.self, from: "\"POSTGRESQL\"".data(using: .utf8)!)
        XCTAssertEqual(decodedPostgres, .POSTGRESQL)
        
        let decodedRedis = try decoder.decode(DatabaseType.self, from: "\"REDIS\"".data(using: .utf8)!)
        XCTAssertEqual(decodedRedis, .REDIS)
    }
    
    func testDatabaseTypeDecodingInvalidValue() {
        let decoder = JSONDecoder()
        let invalidJson = "\"INVALID_DB_TYPE\"".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(DatabaseType.self, from: invalidJson)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testDatabaseTypeEquality() {
        XCTAssertEqual(DatabaseType.POSTGRESQL, DatabaseType.POSTGRESQL)
        XCTAssertNotEqual(DatabaseType.POSTGRESQL, DatabaseType.MYSQL)
        XCTAssertNotEqual(DatabaseType.MONGODB, DatabaseType.REDIS)
        XCTAssertNotEqual(DatabaseType.SQLITE, DatabaseType.ORACLE)
    }
    
    // MARK: - Database Type Usage Tests
    
    func testDatabaseInstanceWithDifferentTypes() {
        let postgresDB = DatabaseInstance(
            name: "Postgres DB",
            databaseType: .POSTGRESQL,
            connectionString: "postgresql://localhost:5432/db"
        )
        XCTAssertEqual(postgresDB.databaseType, .POSTGRESQL)
        
        let mysqlDB = DatabaseInstance(
            name: "MySQL DB",
            databaseType: .MYSQL,
            connectionString: "mysql://localhost:3306/db"
        )
        XCTAssertEqual(mysqlDB.databaseType, .MYSQL)
        
        let mongoDB = DatabaseInstance(
            name: "Mongo DB",
            databaseType: .MONGODB,
            connectionString: "mongodb://localhost:27017/db"
        )
        XCTAssertEqual(mongoDB.databaseType, .MONGODB)
        
        let redisDB = DatabaseInstance(
            name: "Redis DB",
            databaseType: .REDIS,
            connectionString: "redis://localhost:6379/0"
        )
        XCTAssertEqual(redisDB.databaseType, .REDIS)
    }
    
    func testDatabaseInstanceWithNoSQLTypes() {
        let elasticsearchDB = DatabaseInstance(
            name: "Elasticsearch",
            databaseType: .ELASTICSEARCH,
            connectionString: "http://localhost:9200"
        )
        XCTAssertEqual(elasticsearchDB.databaseType, .ELASTICSEARCH)
        
        let cassandraDB = DatabaseInstance(
            name: "Cassandra",
            databaseType: .CASSANDRA,
            connectionString: "cassandra://localhost:9042/keyspace"
        )
        XCTAssertEqual(cassandraDB.databaseType, .CASSANDRA)
    }
    
    func testDatabaseInstanceWithEnterpriseTypes() {
        let oracleDB = DatabaseInstance(
            name: "Oracle DB",
            databaseType: .ORACLE,
            connectionString: "oracle://localhost:1521/xe"
        )
        XCTAssertEqual(oracleDB.databaseType, .ORACLE)
        
        let mssqlDB = DatabaseInstance(
            name: "SQL Server",
            databaseType: .MSSQL,
            connectionString: "mssql://localhost:1433/database"
        )
        XCTAssertEqual(mssqlDB.databaseType, .MSSQL)
    }
    
    func testDatabaseInstanceWithLightweightType() {
        let sqliteDB = DatabaseInstance(
            name: "SQLite DB",
            databaseType: .SQLITE,
            connectionString: "sqlite:///path/to/database.db"
        )
        XCTAssertEqual(sqliteDB.databaseType, .SQLITE)
    }
    
    // MARK: - Connection String Tests
    
    func testDatabaseInstanceConnectionStrings() {
        let databases = [
            DatabaseInstance(name: "PG", databaseType: .POSTGRESQL, connectionString: "postgresql://user:pass@host:5432/db"),
            DatabaseInstance(name: "MySQL", databaseType: .MYSQL, connectionString: "mysql://user:pass@host:3306/db"),
            DatabaseInstance(name: "Mongo", databaseType: .MONGODB, connectionString: "mongodb://user:pass@host:27017/db"),
            DatabaseInstance(name: "Redis", databaseType: .REDIS, connectionString: "redis://host:6379/0"),
            DatabaseInstance(name: "ES", databaseType: .ELASTICSEARCH, connectionString: "http://host:9200"),
            DatabaseInstance(name: "Cassandra", databaseType: .CASSANDRA, connectionString: "cassandra://host:9042/keyspace"),
            DatabaseInstance(name: "SQLite", databaseType: .SQLITE, connectionString: "sqlite:///path/to/db.sqlite"),
            DatabaseInstance(name: "Oracle", databaseType: .ORACLE, connectionString: "oracle://host:1521/xe"),
            DatabaseInstance(name: "MSSQL", databaseType: .MSSQL, connectionString: "mssql://host:1433/db")
        ]
        
        XCTAssertTrue(databases[0].connectionString.contains("postgresql://"))
        XCTAssertTrue(databases[1].connectionString.contains("mysql://"))
        XCTAssertTrue(databases[2].connectionString.contains("mongodb://"))
        XCTAssertTrue(databases[3].connectionString.contains("redis://"))
        XCTAssertTrue(databases[4].connectionString.contains("http://"))
        XCTAssertTrue(databases[5].connectionString.contains("cassandra://"))
        XCTAssertTrue(databases[6].connectionString.contains("sqlite://"))
        XCTAssertTrue(databases[7].connectionString.contains("oracle://"))
        XCTAssertTrue(databases[8].connectionString.contains("mssql://"))
    }
    
    // MARK: - Configuration Tests
    
    func testDatabaseInstanceConfigurationForDifferentTypes() {
        let postgresConfig = [
            "ssl_mode": "require",
            "max_connections": "100",
            "statement_timeout": "30000"
        ]
        let postgresDB = DatabaseInstance(
            name: "Postgres",
            databaseType: .POSTGRESQL,
            connectionString: "postgresql://localhost:5432/db",
            config: postgresConfig
        )
        XCTAssertEqual(postgresDB.config["ssl_mode"], "require")
        
        let redisConfig = [
            "max_memory": "256mb",
            "timeout": "300",
            "tcp_keepalive": "60"
        ]
        let redisDB = DatabaseInstance(
            name: "Redis",
            databaseType: .REDIS,
            connectionString: "redis://localhost:6379/0",
            config: redisConfig
        )
        XCTAssertEqual(redisDB.config["max_memory"], "256mb")
        
        let mongoConfig = [
            "replica_set": "rs0",
            "read_preference": "secondary",
            "write_concern": "majority"
        ]
        let mongoDB = DatabaseInstance(
            name: "MongoDB",
            databaseType: .MONGODB,
            connectionString: "mongodb://localhost:27017/db",
            config: mongoConfig
        )
        XCTAssertEqual(mongoDB.config["replica_set"], "rs0")
    }
}