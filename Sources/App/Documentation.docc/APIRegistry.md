# API Registry

Система управления реестром API сервисов для микросервисной архитектуры.

## Обзор

API Registry - это централизованная система для управления метаданными микросервисов, их API эндпоинтов, зависимостей и конфигураций окружений. Система построена на Swift Vapor 4 и использует PostgreSQL в качестве основной базы данных.

### Основные возможности

- **Управление сервисами**: Регистрация, обновление и удаление микросервисов
- **Управление окружениями**: Конфигурация различных сред развертывания (dev, staging, prod)
- **Управление базами данных**: Регистрация и связывание баз данных с сервисами
- **Управление зависимостями**: Отслеживание межсервисных зависимостей
- **Генерация OpenAPI**: Автоматическая генерация OpenAPI спецификаций
- **API эндпоинты**: Управление метаданными REST API эндпоинтов

### Архитектура

Система следует принципам чистой архитектуры и разделена на следующие слои:

- **Models**: Модели данных с использованием Fluent ORM
- **DTOs**: Объекты передачи данных для API
- **Controllers**: Контроллеры для обработки HTTP запросов
- **Utils**: Вспомогательные утилиты и расширения

## Темы

### Модели данных

- <doc:Service>
- <doc:ServiceEnvironment>
- <doc:DatabaseInstance>
- <doc:Endpoint>
- <doc:Dependency>
- <doc:ServiceDbLink>

### DTO (Data Transfer Objects)

- <doc:ServiceDTOs>
- <doc:ServiceEnvironmentDTOs>
- <doc:DatabaseDTOs>
- <doc:EndpointDTOs>
- <doc:DependencyDTOs>

### Контроллеры и API

- <doc:SimpleServiceController>
- <doc:DatabaseController>
- <doc:EndpointController>
- <doc:DependencyController>

### Утилиты

- <doc:AnyCodable>
- <doc:ServiceType>
- <doc:DatabaseType>
- <doc:EnvironmentStatus>

## Быстрый старт

### Установка и запуск

```bash
# Клонирование репозитория
git clone https://github.com/amattit/api-registry.git
cd api-registry

# Запуск с Docker Compose
docker-compose up -d

# Или локальный запуск
swift run
```

### Базовые операции

#### Создание сервиса

```bash
curl -X POST http://localhost:8080/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "user-service",
    "description": "Сервис управления пользователями",
    "owner": "backend-team",
    "tags": ["users", "authentication"],
    "serviceType": "APPLICATION",
    "supportsDatabase": true,
    "proxy": false
  }'
```

#### Получение списка сервисов

```bash
curl http://localhost:8080/services
```

#### Создание окружения для сервиса

```bash
curl -X PUT http://localhost:8080/services/{serviceId}/environments/prod \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "Production",
    "host": "https://user-service.prod.example.com",
    "config": {
      "timeoutMs": 5000,
      "retries": 3
    },
    "status": "ACTIVE"
  }'
```

## API Endpoints

### Сервисы

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/services` | Создание нового сервиса |
| GET | `/services` | Получение списка всех сервисов |
| GET | `/services/{id}` | Получение сервиса по ID |
| PATCH | `/services/{id}` | Обновление сервиса |
| DELETE | `/services/{id}` | Удаление сервиса |

### Окружения сервисов

| Метод | Путь | Описание |
|-------|------|----------|
| PUT | `/services/{id}/environments/{code}` | Создание/обновление окружения |
| DELETE | `/services/{id}/environments/{code}` | Удаление окружения |

### Базы данных

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/databases` | Создание новой базы данных |
| GET | `/databases` | Получение списка баз данных |
| GET | `/databases/{id}` | Получение базы данных по ID |
| PATCH | `/databases/{id}` | Обновление базы данных |
| DELETE | `/databases/{id}` | Удаление базы данных |

### Связи сервисов с базами данных

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/services/{id}/databases` | Создание связи сервиса с БД |
| GET | `/services/{id}/databases` | Получение связей сервиса с БД |
| DELETE | `/services/{id}/databases/{dbId}` | Удаление связи сервиса с БД |

## Примеры использования

### Регистрация микросервиса с полной конфигурацией

```swift
// 1. Создание сервиса
let service = CreateServiceRequest(
    name: "payment-service",
    description: "Сервис обработки платежей",
    owner: "payments-team",
    tags: ["payments", "billing", "financial"],
    serviceType: .APPLICATION,
    supportsDatabase: true,
    proxy: false
)

// 2. Создание окружений
let prodEnv = UpsertServiceEnvironmentRequest(
    displayName: "Production",
    host: "https://payments.example.com",
    config: EnvironmentConfig(
        timeoutMs: 10000,
        retries: 3,
        downstreamOverrides: [
            "bank-api": "https://bank-api.prod.example.com"
        ]
    ),
    status: .ACTIVE
)

// 3. Регистрация базы данных
let database = CreateDatabaseRequest(
    name: "payments-db",
    description: "Основная база данных платежей",
    databaseType: .POSTGRESQL,
    connectionString: "postgresql://user:pass@db.example.com:5432/payments",
    config: [
        "max_connections": "100",
        "ssl_mode": "require"
    ]
)
```

## Безопасность

- Все API эндпоинты поддерживают аутентификацию
- Валидация входных данных на уровне DTO
- Защита от SQL инъекций через Fluent ORM
- Логирование всех операций изменения данных

## Мониторинг и логирование

Система интегрирована с:
- Structured logging через Swift-log
- Metrics через Swift-metrics
- Health checks для всех зависимостей
- Distributed tracing поддержка