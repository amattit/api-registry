import Vapor
import Fluent

struct OpenAPILoaderService {
    let client: Client
    let db: Database
    
    init(client: Client, db: Database) {
        self.client = client
        self.db = db
    }
    
    func loadAndProcessOpenAPISpec(from url: String, overwrite: Bool = true) async throws -> LoadOpenAPISpecResponse {
        // 1. Загружаем спецификацию по URL
        let openAPISpec = try await fetchOpenAPISpec(from: url)
        
        // 2. Ищем существующий сервис или создаем новый
        let service = try await findOrCreateService(from: openAPISpec, overwrite: overwrite)
        
        // 3. Обрабатываем endpoints
        let (created, updated) = try await processEndpoints(for: service, from: openAPISpec, overwrite: overwrite)
        
        return LoadOpenAPISpecResponse(
            success: true,
            message: "OpenAPI specification loaded successfully",
            serviceId: service.id,
            endpointsCreated: created,
            endpointsUpdated: updated
        )
    }
    
    private func fetchOpenAPISpec(from url: String) async throws -> OpenAPISpec {
        let uri = URI(string: url)
        
        let response = try await client.get(uri)
        
        guard response.status == .ok else {
            throw Abort(.badRequest, reason: "Failed to fetch OpenAPI specification: HTTP \(response.status.code)")
        }
        
        guard let body = response.body else {
            throw Abort(.badRequest, reason: "Empty response body")
        }
        
        let data = Data(body.readableBytesView)
        
        do {
            return try JSONDecoder().decode(OpenAPISpec.self, from: data)
        } catch {
            throw Abort(.badRequest, reason: "Failed to parse OpenAPI specification: \(error.localizedDescription)")
        }
    }
    
    private func findOrCreateService(from spec: OpenAPISpec, overwrite: Bool) async throws -> Service {
        // Ищем существующий сервис по имени
        if let existingService = try await Service.query(on: db)
            .filter(\.$name == spec.info.title)
            .first() {
            
            if overwrite {
                // Обновляем существующий сервис
                existingService.description = spec.info.description
                existingService.updatedAt = Date()
                try await existingService.save(on: db)
                return existingService
            } else {
                return existingService
            }
        } else {
            // Создаем новый сервис
            let newService = Service(
                name: spec.info.title,
                description: spec.info.description,
                owner: "OpenAPI Import",
                tags: extractTagsFromSpec(spec),
                serviceType: .APPLICATION,
                supportsDatabase: false,
                proxy: false
            )
            
            try await newService.save(on: db)
            return newService
        }
    }
    
    private func processEndpoints(for service: Service, from spec: OpenAPISpec, overwrite: Bool) async throws -> (created: Int, updated: Int) {
        var createdCount = 0
        var updatedCount = 0
        
        if overwrite {
            // Удаляем все существующие endpoints для этого сервиса
            try await Endpoint.query(on: db)
                .filter(\.$service.$id == service.id!)
                .delete()
        }
        
        for (path, methods) in spec.paths {
            for (httpMethod, operation) in methods {
                let endpoint = try await createOrUpdateEndpoint(
                    service: service,
                    path: path,
                    method: httpMethod,
                    operation: operation,
                    overwrite: overwrite
                )
                
                if endpoint.createdAt == endpoint.updatedAt {
                    createdCount += 1
                } else {
                    updatedCount += 1
                }
            }
        }
        
        return (created: createdCount, updated: updatedCount)
    }
    
    private func createOrUpdateEndpoint(
        service: Service,
        path: String,
        method: String,
        operation: OpenAPIOperation,
        overwrite: Bool
    ) async throws -> Endpoint {
        
        guard let endpointMethod = EndpointMethod(rawValue: method.uppercased()) else {
            throw Abort(.badRequest, reason: "Unsupported HTTP method: \(method)")
        }
        
        let existingEndpoint = try await Endpoint.query(on: db)
            .filter(\.$service.$id == service.id!)
            .filter(\.$path == path)
            .filter(\.$method == endpointMethod)
            .first()
        
        if let existing = existingEndpoint, !overwrite {
            return existing
        }
        
        // Подготавливаем данные для endpoint
        let summary = operation.summary ?? "No summary provided"
        let requestSchema = try buildRequestSchema(from: operation)
        let responseSchemas = try buildResponseSchemas(from: operation)
        let auth = try buildAuthSchema(from: operation)
        let metadata = try buildMetadata(from: operation)
        
        if let existing = existingEndpoint {
            // Обновляем существующий endpoint
            existing.summary = summary
            existing.requestSchema = requestSchema
            existing.responseSchemas = responseSchemas
            existing.auth = auth
            existing.metadata = metadata
            existing.updatedAt = Date()
            
            try await existing.save(on: db)
            return existing
        } else {
            // Создаем новый endpoint
            let newEndpoint = Endpoint(
                serviceId: service.id!,
                method: endpointMethod,
                path: path,
                summary: summary,
                requestSchema: requestSchema,
                responseSchemas: responseSchemas,
                auth: auth,
                rateLimit: nil,
                metadata: metadata
            )
            
            try await newEndpoint.save(on: db)
            return newEndpoint
        }
    }
    
    private func extractTagsFromSpec(_ spec: OpenAPISpec) -> [String] {
        var tags = Set<String>()
        
        for (_, methods) in spec.paths {
            for (_, operation) in methods {
                if let operationTags = operation.tags {
                    tags.formUnion(operationTags)
                }
            }
        }
        
        return Array(tags)
    }
    
    private func buildRequestSchema(from operation: OpenAPIOperation) throws -> [String: AnyCodable]? {
        guard operation.requestBody != nil || operation.parameters != nil else { return nil }
        
        var schema: [String: AnyCodable] = [:]
        
        // Обрабатываем requestBody
        if let requestBody = operation.requestBody {
            if let content = requestBody.content {
                // Конвертируем [String: AnyCodable] в простой словарь
                let contentDict = convertAnyCodableDict(content)
                schema["content"] = AnyCodable(contentDict)
            }
            
            if let required = requestBody.required {
                schema["required"] = AnyCodable(required)
            }
        }
        
        // Обрабатываем parameters
        if let parameters = operation.parameters {
            var parametersArray: [[String: Any]] = []
            
            for param in parameters {
                var paramDict: [String: Any] = [
                    "name": param.name,
                    "in": param.in
                ]
                
                if let description = param.description {
                    paramDict["description"] = description
                }
                
                if let required = param.required {
                    paramDict["required"] = required
                }
                
                if let paramSchema = param.schema {
                    paramDict["schema"] = convertAnyCodableDict(paramSchema)
                }
                
                parametersArray.append(paramDict)
            }
            
            schema["parameters"] = AnyCodable(parametersArray)
        }
        
        return schema.isEmpty ? nil : schema
    }
    
    private func buildResponseSchemas(from operation: OpenAPIOperation) throws -> [String: AnyCodable]? {
        guard let responses = operation.responses else { return nil }
        
        var schemas: [String: Any] = [:]
        
        for (statusCode, response) in responses {
            var responseData: [String: Any] = [
                "description": response.description
            ]
            
            if let content = response.content {
                responseData["content"] = convertAnyCodableDict(content)
            }
            
            schemas[statusCode] = responseData
        }
        
        return schemas.isEmpty ? nil : ["responses": AnyCodable(schemas)]
    }
    
    private func buildAuthSchema(from operation: OpenAPIOperation) throws -> [String: AnyCodable]? {
        guard let security = operation.security else { return nil }
        
        return ["security": AnyCodable(security)]
    }
    
    private func buildMetadata(from operation: OpenAPIOperation) throws -> [String: AnyCodable]? {
        var metadata: [String: Any] = [:]
        
        if let description = operation.description {
            metadata["description"] = description
        }
        
        if let operationId = operation.operationId {
            metadata["operationId"] = operationId
        }
        
        if let tags = operation.tags {
            metadata["tags"] = tags
        }
        
        if metadata.isEmpty {
            return nil
        }
        
        // Возвращаем каждое поле отдельно, а не в обертке
        var result: [String: AnyCodable] = [:]
        for (key, value) in metadata {
            result[key] = AnyCodable(value)
        }
        
        return result
    }
    
    // Вспомогательная функция для конвертации AnyCodable словарей в простые словари
    private func convertAnyCodableDict(_ dict: [String: AnyCodable]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, value) in dict {
            result[key] = convertAnyCodableValue(value)
        }
        
        return result
    }
    
    // Вспомогательная функция для конвертации AnyCodable значений
    private func convertAnyCodableValue(_ value: AnyCodable) -> Any {
        switch value.value {
        case let dict as [String: AnyCodable]:
            return convertAnyCodableDict(dict)
        case let array as [AnyCodable]:
            return array.map { convertAnyCodableValue($0) }
        case let dict as [String: Any]:
            return dict
        case let array as [Any]:
            return array
        default:
            return value.value
        }
    }
}
