import Fluent
import Vapor

struct DependencyGraphController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let graph = routes.grouped("dependency-graph")
        
        // Dependency graph endpoints
        graph.get("services", use: getServiceDependencyGraph)
        graph.get("services", ":serviceId", use: getServiceDependencies)
        graph.get("endpoints", ":endpointId", use: getEndpointDependencies)
    }
    
    // MARK: - Service Dependency Graph
    
    func getServiceDependencyGraph(req: Request) async throws -> ServiceDependencyGraphResponse {
        // Get all services with their dependencies
        let services = try await Service.query(on: req.db)
            .with(\.$serviceDependencies) { dep in
                dep.with(\.$dependency)
            }
            .all()
        
        var nodes: [DependencyNode] = []
        var edges: [DependencyEdge] = []
        
        // Create nodes for all services
        for service in services {
            nodes.append(DependencyNode(
                id: service.id!.uuidString,
                name: service.name,
                type: "service",
                serviceType: service.serviceType.rawValue,
                metadata: [
                    "description": AnyCodable(service.description ?? ""),
                    "owner": AnyCodable(service.owner),
                    "tags": AnyCodable(service.tags)
                ]
            ))
        }
        
        // Create edges for service dependencies
        for service in services {
            for serviceDep in service.serviceDependencies {
                edges.append(DependencyEdge(
                    from: service.id!.uuidString,
                    to: serviceDep.dependency.id!.uuidString,
                    type: "service_dependency",
                    metadata: [
                        "dependencyType": AnyCodable(serviceDep.dependency.dependencyType.rawValue),
                        "version": AnyCodable(serviceDep.dependency.version)
                    ]
                ))
            }
        }
        
        return ServiceDependencyGraphResponse(
            nodes: nodes,
            edges: edges,
            metadata: [
                "totalServices": AnyCodable(services.count),
                "totalDependencies": AnyCodable(edges.count),
                "generatedAt": AnyCodable(ISO8601DateFormatter().string(from: Date()))
            ]
        )
    }
    
    func getServiceDependencies(req: Request) async throws -> ServiceDependencyGraphDetailResponse {
        guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid service ID")
        }
        
        guard let service = try await Service.find(serviceId, on: req.db) else {
            throw Abort(.notFound, reason: "Service not found")
        }
        
        // Get service dependencies
        let serviceDependencies = try await ServiceDependency.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .with(\.$dependency)
            .all()
        
        // Get endpoint dependencies for this service
        let endpoints = try await Endpoint.query(on: req.db)
            .filter(\.$service.$id == serviceId)
            .with(\.$endpointDependencies) { dep in
                dep.with(\.$dependency)
            }
            .all()
        
        var endpointDeps: [EndpointDependencyInfo] = []
        for endpoint in endpoints {
            for endpointDep in endpoint.endpointDependencies {
                endpointDeps.append(EndpointDependencyInfo(
                    endpointId: endpoint.id!,
                    endpointPath: endpoint.path,
                    endpointMethod: endpoint.method.rawValue,
                    dependency: DependencyInfo(
                        dependencyId: endpointDep.dependency.id!,
                        name: endpointDep.dependency.name,
                        type: endpointDep.dependency.dependencyType.rawValue,
                        version: endpointDep.dependency.version
                    )
                ))
            }
        }
        
        return ServiceDependencyGraphDetailResponse(
            serviceId: serviceId,
            serviceName: service.name,
            serviceDependencies: serviceDependencies.map { dep in
                DependencyInfo(
                    dependencyId: dep.dependency.id!,
                    name: dep.dependency.name,
                    type: dep.dependency.dependencyType.rawValue,
                    version: dep.dependency.version
                )
            },
            endpointDependencies: endpointDeps
        )
    }
    
    func getEndpointDependencies(req: Request) async throws -> EndpointDependencyResponse {
        guard let endpointId = req.parameters.get("endpointId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid endpoint ID")
        }
        
        guard let endpoint = try await Endpoint.find(endpointId, on: req.db) else {
            throw Abort(.notFound, reason: "Endpoint not found")
        }
        
        // Get endpoint dependencies
        let endpointDependencies = try await EndpointDependency.query(on: req.db)
            .filter(\.$endpoint.$id == endpointId)
            .with(\.$dependency)
            .all()
        
        // Get endpoint databases
        let endpointDatabases = try await EndpointDatabase.query(on: req.db)
            .filter(\.$endpoint.$id == endpointId)
            .with(\.$database)
            .all()
        
        return EndpointDependencyResponse(
            endpointId: endpointId,
            path: endpoint.path,
            method: endpoint.method.rawValue,
            summary: endpoint.summary,
            dependencies: endpointDependencies.map { dep in
                DependencyInfo(
                    dependencyId: dep.dependency.id!,
                    name: dep.dependency.name,
                    type: dep.dependency.dependencyType.rawValue,
                    version: dep.dependency.version
                )
            },
            databases: endpointDatabases.map { db in
                DatabaseInfo(
                    databaseId: db.database.id!,
                    name: db.database.name,
                    type: db.database.databaseType.rawValue,
                    host: db.database.connectionString
                )
            }
        )
    }
}

// MARK: - Response DTOs

struct DependencyNode: Content {
    let id: String
    let name: String
    let type: String
    let serviceType: String?
    let metadata: [String: AnyCodable]
    
    init(id: String, name: String, type: String, serviceType: String? = nil, metadata: [String: AnyCodable] = [:]) {
        self.id = id
        self.name = name
        self.type = type
        self.serviceType = serviceType
        self.metadata = metadata
    }
}

struct DependencyEdge: Content {
    let from: String
    let to: String
    let type: String
    let metadata: [String: AnyCodable]
    
    init(from: String, to: String, type: String, metadata: [String: AnyCodable] = [:]) {
        self.from = from
        self.to = to
        self.type = type
        self.metadata = metadata
    }
}

struct ServiceDependencyGraphResponse: Content {
    let nodes: [DependencyNode]
    let edges: [DependencyEdge]
    let metadata: [String: AnyCodable]
}

struct DependencyInfo: Content {
    let dependencyId: UUID
    let name: String
    let type: String
    let version: String?
}

struct DatabaseInfo: Content {
    let databaseId: UUID
    let name: String
    let type: String
    let host: String
}

struct EndpointDependencyInfo: Content {
    let endpointId: UUID
    let endpointPath: String
    let endpointMethod: String
    let dependency: DependencyInfo
}

struct ServiceDependencyGraphDetailResponse: Content {
    let serviceId: UUID
    let serviceName: String
    let serviceDependencies: [DependencyInfo]
    let endpointDependencies: [EndpointDependencyInfo]
}

struct EndpointDependencyResponse: Content {
    let endpointId: UUID
    let path: String
    let method: String
    let summary: String
    let dependencies: [DependencyInfo]
    let databases: [DatabaseInfo]
}
