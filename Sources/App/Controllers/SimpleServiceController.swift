import Fluent
import Vapor

struct SimpleServiceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let services = routes.grouped("services")
        
        // Service CRUD
        services.post(use: create)
        services.get(":serviceId", use: show)
        services.patch(":serviceId", use: update)
        services.delete(":serviceId", use: delete)
        services.get(use: list)
        
        // Service environments
        services.put(":serviceId", "environments", ":envCode", use: upsertEnvironment)
        services.delete(":serviceId", "environments", ":envCode", use: deleteEnvironment)
        
        // OpenAPI generation
        services.post(":serviceId", "generate-openapi", use: generateOpenAPI)
    }
    
    // MARK: - Service CRUD
    
    func create(req: Request) async throws -> ServiceResponse {
        try CreateServiceRequest.validate(content: req)
        let createRequest = try req.content.decode(CreateServiceRequest.self)
        
        // Check if service name already exists
        if let _ = try await Service.query(on: req.db)
            .filter(\.$name == createRequest.name)
            .first() {
            throw Abort(.conflict, reason: "Service with name '\(createRequest.name)' already exists")
        }
        
        let service = Service(
            name: createRequest.name,
            description: createRequest.description,
            owner: createRequest.owner,
            tags: createRequest.tags,
            serviceType: createRequest.serviceType,
            supportsDatabase: createRequest.supportsDatabase,
            proxy: createRequest.proxy
        )
        
        try await service.save(on: req.db)
        return ServiceResponse(from: service)
    }
    
    func show(req: Request) async throws -> ServiceResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let service = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        return ServiceResponse(from: service)
    }
    
    func list(req: Request) async throws -> [ServiceResponse] {
        let services = try await Service.query(on: req.db).all()
        return services.map { ServiceResponse(from: $0) }
    }
    
    func update(req: Request) async throws -> ServiceResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let service = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        try UpdateServiceRequest.validate(content: req)
        let updateRequest = try req.content.decode(UpdateServiceRequest.self)
        
        if let name = updateRequest.name {
            // Check if new name conflicts with existing service
            if try await Service.query(on: req.db)
                .filter(\.$name == name)
                .filter(\.$id != serviceId)
                .first() != nil {
                throw Abort(.conflict, reason: "Service with name '\(name)' already exists")
            }
            service.name = name
        }
        
        if let description = updateRequest.description {
            service.description = description
        }
        
        if let owner = updateRequest.owner {
            service.owner = owner
        }
        
        if let tags = updateRequest.tags {
            service.tags = tags
        }
        
        if let serviceType = updateRequest.serviceType {
            service.serviceType = serviceType
        }
        
        if let supportsDatabase = updateRequest.supportsDatabase {
            service.supportsDatabase = supportsDatabase
        }
        
        if let proxy = updateRequest.proxy {
            service.proxy = proxy
        }
        
        service.updatedAt = Date()
        try await service.save(on: req.db)
        
        return ServiceResponse(from: service)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let service = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        try await service.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - Environment Management
    
    func upsertEnvironment(req: Request) async throws -> ServiceEnvironmentResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let envCode = req.parameters.get("envCode") else {
            throw Abort(.badRequest, reason: "Invalid environment code")
        }
        
        guard let _ = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        struct UpsertRequest: Content {
            let displayName: String
            let host: String
            let config: EnvironmentConfig?
            let status: EnvironmentStatus?
        }
        
        let upsertRequest = try req.content.decode(UpsertRequest.self)
        
        // Check if environment already exists
        if let existingEnv = try await ServiceEnvironment.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$code == envCode)
            .first() {
            
            // Update existing environment
            existingEnv.displayName = upsertRequest.displayName
            existingEnv.host = upsertRequest.host
            existingEnv.config = upsertRequest.config
            if let status = upsertRequest.status {
                existingEnv.status = status
            }
            existingEnv.updatedAt = Date()
            try await existingEnv.save(on: req.db)
            
            return ServiceEnvironmentResponse(from: existingEnv)
        } else {
            // Create new environment
            let newEnv = ServiceEnvironment(
                serviceID: serviceId,
                code: envCode,
                displayName: upsertRequest.displayName,
                host: upsertRequest.host,
                config: upsertRequest.config,
                status: upsertRequest.status ?? .ACTIVE
            )
            
            try await newEnv.save(on: req.db)
            return ServiceEnvironmentResponse(from: newEnv)
        }
    }
    
    func deleteEnvironment(req: Request) async throws -> HTTPStatus {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let envCode = req.parameters.get("envCode") else {
            throw Abort(.badRequest, reason: "Invalid environment code")
        }
        
        guard let environment = try await ServiceEnvironment.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$code == envCode)
            .first() else {
            throw Abort(.notFound, reason: "Environment not found")
        }
        
        try await environment.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - OpenAPI Generation
    
    func generateOpenAPI(req: Request) async throws -> Response {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let envCode = req.query[String.self, at: "env"] else {
            throw Abort(.badRequest, reason: "Environment code is required")
        }
        
        // Get service
        guard let service = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        // Get environment
        guard let environment = try await ServiceEnvironment.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .filter(\.$code == envCode)
            .first() else {
            throw Abort(.notFound, reason: "Environment not found")
        }
        
        // Get endpoints with dependencies and databases
        let endpoints = try await Endpoint.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .with(\.$endpointDependencies) { dep in
                dep.with(\.$dependency)
            }
            .with(\.$endpointDatabases) { db in
                db.with(\.$database)
            }
            .all()
        
        // Generate OpenAPI spec
        let openAPISpec = generateOpenAPISpec(
            service: service,
            environment: environment,
            endpoints: endpoints
        )
        
        // Check format preference
        let format = req.query[String.self, at: "format"] ?? "json"
        let acceptHeader = req.headers.first(name: .accept) ?? "application/json"
        
        if format == "yaml" || acceptHeader.contains("application/yaml") {
            // Return YAML format (simplified for now)
            let yamlContent = convertToYAML(openAPISpec)
            return Response(
                status: .ok,
                headers: HTTPHeaders([("Content-Type", "application/yaml")]),
                body: .init(string: yamlContent)
            )
        } else {
            // Return JSON format
            let jsonData = try JSONSerialization.data(withJSONObject: openAPISpec, options: .prettyPrinted)
            return Response(
                status: .ok,
                headers: HTTPHeaders([("Content-Type", "application/json")]),
                body: .init(data: jsonData)
            )
        }
    }
    
    private func generateOpenAPISpec(
        service: Service,
        environment: ServiceEnvironment,
        endpoints: [Endpoint]
    ) -> [String: Any] {
        var paths: [String: [String: Any]] = [:]
        
        // Process each endpoint
        for endpoint in endpoints {
            let pathKey = endpoint.path
            let methodKey = endpoint.method.rawValue.lowercased()
            
            var operation: [String: Any] = [
                "summary": endpoint.summary,
                "operationId": "\(methodKey)\(pathKey.replacingOccurrences(of: "/", with: "_"))"
            ]
            
            // Add request body if present
            if let requestSchema = endpoint.requestSchema {
                // Convert AnyCodable dictionary to Any dictionary
                let schemaDict = requestSchema.mapValues { $0.value }
                operation["requestBody"] = [
                    "required": true,
                    "content": [
                        "application/json": [
                            "schema": schemaDict
                        ]
                    ]
                ]
            }
            
            // Add responses
            var responses: [String: Any] = [:]
            if let responseSchemas = endpoint.responseSchemas {
                for (statusCode, schema) in responseSchemas {
                    responses[statusCode] = [
                        "description": "Response for status \(statusCode)",
                        "content": [
                            "application/json": [
                                "schema": schema.value
                            ]
                        ]
                    ]
                }
            } else {
                responses["200"] = [
                    "description": "Success"
                ]
            }
            operation["responses"] = responses
            
            // Add security if needed
            if let auth = endpoint.auth, let typeValue = auth["type"] {
                let authType = typeValue.value as? String ?? "bearer"
                operation["security"] = [[authType: []]]
            }
            
            // Initialize path if not exists
            if paths[pathKey] == nil {
                paths[pathKey] = [:]
            }
            paths[pathKey]![methodKey] = operation
        }
        
        return [
            "openapi": "3.0.0",
            "info": [
                "title": service.name,
                "description": service.description ?? "",
                "version": "1.0.0"
            ],
            "servers": [[
                "url": environment.host,
                "description": "\(environment.code) environment"
            ]],
            "paths": paths
        ]
    }
    
    private func convertToYAML(_ spec: [String: Any]) -> String {
        // Simplified YAML conversion - in production, use a proper YAML library
        let info = spec["info"] as? [String: Any] ?? [:]
        let servers = spec["servers"] as? [[String: Any]] ?? []
        let serverUrl = servers.first?["url"] as? String ?? ""
        
        return """
        openapi: 3.0.0
        info:
          title: \(info["title"] as? String ?? "")
          version: \(info["version"] as? String ?? "1.0.0")
        servers:
          - url: \(serverUrl)
        paths: {}
        """
    }
}