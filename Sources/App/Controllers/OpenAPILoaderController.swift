import Vapor
import Fluent

struct OpenAPILoaderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let openapi = routes.grouped("openapi")
        
        openapi.post("load", use: loadOpenAPISpec)
        openapi.get("status", ":serviceId", use: getLoadStatus)
    }
    
    func loadOpenAPISpec(req: Request) async throws -> LoadOpenAPISpecResponse {
        let loadRequest = try req.content.decode(LoadOpenAPISpecRequest.self)
        
        // Валидация URL
        guard !loadRequest.url.isEmpty else {
            throw Abort(.badRequest, reason: "URL cannot be empty")
        }
        
        guard URL(string: loadRequest.url) != nil else {
            throw Abort(.badRequest, reason: "Invalid URL format")
        }
        
        let loaderService = OpenAPILoaderService(client: req.client, db: req.db)
        
        do {
            let response = try await loaderService.loadAndProcessOpenAPISpec(
                from: loadRequest.url,
                overwrite: loadRequest.overwrite ?? true
            )
            
            req.logger.info("Successfully loaded OpenAPI spec from \(loadRequest.url)")
            req.logger.info("Service ID: \(response.serviceId?.uuidString ?? "unknown")")
            req.logger.info("Endpoints created: \(response.endpointsCreated), updated: \(response.endpointsUpdated)")
            
            return response
        } catch let error as AbortError {
            req.logger.error("Failed to load OpenAPI spec: \(error.reason)")
            throw error
        } catch {
            req.logger.error("Unexpected error loading OpenAPI spec: \(error)")
            throw Abort(.internalServerError, reason: "Failed to process OpenAPI specification: \(error.localizedDescription)")
        }
    }
    
    func getLoadStatus(req: Request) async throws -> ServiceLoadStatusResponse {
        guard let serviceIdString = req.parameters.get("serviceId"),
              let serviceId = UUID(uuidString: serviceIdString) else {
            throw Abort(.badRequest, reason: "Invalid service ID format")
        }
        
        guard let service = try await Service.query(on: req.db)
            .filter(\.$id == serviceId)
            .with(\.$endpoints)
            .first() else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        let endpointsCount = service.endpoints.count
        
        return ServiceLoadStatusResponse(
            serviceId: service.id!,
            serviceName: service.name,
            description: service.description,
            endpointsCount: endpointsCount,
            lastUpdated: service.updatedAt,
            tags: service.tags
        )
    }
}

struct ServiceLoadStatusResponse: Content {
    let serviceId: UUID
    let serviceName: String
    let description: String?
    let endpointsCount: Int
    let lastUpdated: Date?
    let tags: [String]
}