# API Registry Microservice

A comprehensive API registry microservice built with Swift Vapor framework for managing services, environments, dependencies, endpoints, database links, and OpenAPI specification generation.

Микросервис для управления реестром API, их зависимостями, окружениями и генерации OpenAPI спецификаций.

## Возможности

- Управление сервисами и их метаданными
- Управление окружениями сервисов (dev/test/prod)
- Отслеживание зависимостей между сервисами
- Управление эндпоинтами и их описаниями
- Связывание сервисов с базами данных
- Генерация OpenAPI 3.0 спецификаций
- Построение графов зависимостей
- Health check для мониторинга

## Требования

- Swift 5.9+
- PostgreSQL 12+
- Docker (опционально)

## Быстрый старт

### 1. Запуск PostgreSQL

```bash
docker-compose up -d postgres
```

### 2. Установка зависимостей и сборка

```bash
swift package resolve
swift build
```

### 3. Запуск миграций

```bash
swift run App migrate
```

### 4. Запуск сервиса

```bash
swift run App serve --port 8080
```

Сервис будет доступен по адресу: http://localhost:8080

## API Endpoints

### Health Check
- `GET /health` - Проверка состояния сервиса и БД

### Services
- `POST /api/v1/services` - Создание сервиса
- `GET /api/v1/services/{serviceId}` - Получение сервиса
- `PATCH /api/v1/services/{serviceId}` - Обновление сервиса
- `DELETE /api/v1/services/{serviceId}` - Удаление сервиса

### Service Environments
- `PUT /api/v1/services/{serviceId}/environments/{envCode}` - Создание/обновление окружения
- `DELETE /api/v1/services/{serviceId}/environments/{envCode}` - Удаление окружения

### Service Dependencies
- `POST /api/v1/services/{serviceId}/dependencies` - Добавление зависимости
- `DELETE /api/v1/services/{serviceId}/dependencies/{dependencyId}` - Удаление зависимости

### Service Database Links
- `POST /api/v1/services/{serviceId}/databases` - Связывание с БД
- `DELETE /api/v1/services/{serviceId}/databases/{linkId}` - Удаление связи с БД

### Endpoints
- `POST /api/v1/services/{serviceId}/endpoints` - Создание эндпоинта
- `PATCH /api/v1/services/{serviceId}/endpoints/{endpointId}` - Обновление эндпоинта
- `DELETE /api/v1/services/{serviceId}/endpoints/{endpointId}` - Удаление эндпоинта

### Databases
- `POST /api/v1/databases` - Регистрация БД
- `GET /api/v1/databases` - Список БД
- `GET /api/v1/databases/{databaseId}` - Получение БД

### OpenAPI Generation
- `POST /api/v1/services/{serviceId}/generate-openapi?env={envCode}` - Генерация OpenAPI спецификации

### Dependency Graph
- `GET /api/v1/services/{serviceId}/dependencies?direction=downstream&depth=3` - Граф зависимостей

## Примеры использования

### Создание сервиса

```bash
curl -X POST http://localhost:8080/api/v1/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "billing-service",
    "description": "Сервис биллинга",
    "owner": "payments-team",
    "tags": ["payments", "critical"],
    "serviceType": "APPLICATION",
    "supportsDatabase": true,
    "proxy": false
  }'
```

### Создание окружения

```bash
curl -X PUT http://localhost:8080/api/v1/services/{serviceId}/environments/prod \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "Production",
    "host": "https://billing.prod.company.com",
    "config": {
      "timeoutMs": 3000,
      "retries": 2
    },
    "status": "ACTIVE"
  }'
```

### Создание эндпоинта

```bash
curl -X POST http://localhost:8080/api/v1/services/{serviceId}/endpoints \
  -H "Content-Type: application/json" \
  -d '{
    "method": "POST",
    "path": "/api/v1/payments",
    "summary": "Создание платежа",
    "calls": [
      {
        "type": "INTERNAL_SERVICE",
        "targetServiceId": "{targetServiceId}",
        "protocol": "REST",
        "method": "GET",
        "path": "/api/v1/orders/{orderId}"
      }
    ]
  }'
```

## Конфигурация

Переменные окружения:

- `DATABASE_HOST` - Хост PostgreSQL (по умолчанию: localhost)
- `DATABASE_PORT` - Порт PostgreSQL (по умолчанию: 5432)
- `DATABASE_USERNAME` - Пользователь БД (по умолчанию: postgres)
- `DATABASE_PASSWORD` - Пароль БД (по умолчанию: password)
- `DATABASE_NAME` - Имя БД (по умолчанию: api_registry)
- `PORT` - Порт сервиса (по умолчанию: 8080)

## Архитектура

Сервис построен на фреймворке Vapor с использованием:

- **Fluent ORM** для работы с PostgreSQL
- **Layered Architecture**: Controllers → Services → Models
- **DTO Pattern** для валидации входных данных
- **RESTful API** с JSON форматом
- **Database Migrations** для версионирования схемы БД

## Модель данных

- **Service** - Базовое описание сервиса
- **ServiceEnvironment** - Окружения сервиса (dev/test/prod)
- **ServiceDependency** - Зависимости между сервисами
- **Database** - Описание баз данных
- **ServiceDatabaseLink** - Связи сервисов с БД
- **Endpoint** - HTTP эндпоинты сервисов
- **EndpointDependency** - Зависимости эндпоинтов
- **EndpointDatabase** - Связи эндпоинтов с БД

## Разработка

### Запуск тестов

```bash
swift test
```

### Создание новой миграции

```bash
swift run App migrate --dry-run
```

### Откат миграций

```bash
swift run App migrate --revert
```

## CI/CD

Проект включает комплексные GitHub Actions workflows:

### Continuous Integration
- **CI Workflow** (`.github/workflows/ci.yml`): Запускает тесты и линтинг при каждом push и PR
- **Security Workflow** (`.github/workflows/security.yml`): Выполняет сканирование зависимостей и секретов
- **Docker Workflow** (`.github/workflows/docker.yml`): Собирает и публикует Docker образы

### Автоматическое управление зависимостями
- **Dependabot Configuration** (`.github/dependabot.yml`): Автоматически создает PR для обновления зависимостей
- **Auto-merge Workflow** (`.github/workflows/dependabot-auto-merge.yml`): Автоматически мержит PR от Dependabot при прохождении тестов

Auto-merge workflow:
- ✅ Автоматически мержит **patch** и **minor** обновления версий после прохождения тестов
- ⚠️ Требует ручного ревью для **major** обновлений версий
- 🔍 Ждет завершения всех CI проверок перед мержем
- 📝 Добавляет комментарии с объяснением решения о мерже

### Управление релизами
- **Release Workflow** (`.github/workflows/release.yml`): Создает GitHub релизы и собирает артефакты при push тегов

### Настройка Auto-merge

Для включения Dependabot auto-merge в вашем репозитории:

1. Настройте правила защиты ветки для main ветки
2. Включите "Allow auto-merge" в настройках репозитория
3. Workflow автоматически обработает остальное!