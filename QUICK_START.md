# Быстрый старт - OpenAPI Loader

## Запуск проекта

### 1. Запуск через Docker Compose

```bash
# Клонируйте репозиторий (если еще не сделано)
git clone https://github.com/amattit/api-registry.git
cd api-registry

# Запустите проект
docker-compose up -d

# Проверьте, что сервисы запущены
docker-compose ps

# Проверьте здоровье API
curl http://localhost:8080/health
```

### 2. Тестирование OpenAPI Loader

#### Запуск тестового сервера с OpenAPI спецификацией:

```bash
# В отдельном терминале
python test_openapi_server.py
```

Сервер будет доступен на `http://localhost:12001/openapi.json`

#### Загрузка спецификации:

```bash
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://localhost:12001/openapi.json",
    "overwrite": true
  }'
```

Ожидаемый ответ:
```json
{
  "success": true,
  "message": "OpenAPI specification loaded successfully",
  "serviceId": "uuid-here",
  "endpointsCreated": 55,
  "endpointsUpdated": 0
}
```

#### Проверка статуса загруженного сервиса:

```bash
# Замените {serviceId} на ID из предыдущего ответа
curl http://localhost:8080/api/v1/openapi/status/{serviceId}
```

#### Автоматическая демонстрация:

```bash
# Запустите демонстрационный скрипт
python demo_openapi_loader.py
```

## Проверка результатов

### Просмотр созданного сервиса:

```bash
# Получить список всех сервисов
curl http://localhost:8080/api/v1/services

# Получить конкретный сервис
curl http://localhost:8080/api/v1/services/{serviceId}
```

### Просмотр endpoints:

```bash
# Получить все endpoints сервиса
curl http://localhost:8080/api/v1/services/{serviceId}/endpoints

# Или все endpoints в системе
curl http://localhost:8080/api/v1/endpoints
```

## Тестирование с реальными спецификациями

### Примеры публичных OpenAPI спецификаций:

```bash
# Swagger Petstore
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://petstore3.swagger.io/api/v3/openapi.json",
    "overwrite": true
  }'

# JSONPlaceholder API
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://jsonplaceholder.typicode.com/openapi.json",
    "overwrite": true
  }'
```

## Возможные проблемы и решения

### 1. Ошибка подключения к базе данных

```bash
# Проверьте статус PostgreSQL
docker-compose logs postgres

# Перезапустите сервисы
docker-compose restart
```

### 2. Ошибка "Cannot connect to OpenAPI server"

```bash
# Убедитесь, что тестовый сервер запущен
python test_openapi_server.py

# Проверьте доступность
curl http://localhost:12001/openapi.json
```

### 3. Ошибка компиляции Swift

```bash
# Пересоберите образ
docker-compose build --no-cache api-registry
docker-compose up -d
```

### 4. Порты заняты

Измените порты в `docker-compose.yml`:
- API Registry: порт 8080 → другой порт
- PostgreSQL: порт 5432 → другой порт
- Тестовый сервер: порт 12001 → другой порт

## Логи и отладка

### Просмотр логов:

```bash
# Логи API Registry
docker-compose logs -f api-registry

# Логи PostgreSQL
docker-compose logs -f postgres

# Все логи
docker-compose logs -f
```

### Подключение к базе данных:

```bash
# Подключение к PostgreSQL
docker-compose exec postgres psql -U postgres -d api_registry

# Просмотр таблиц
\dt

# Просмотр сервисов
SELECT id, name, description FROM services;

# Просмотр endpoints
SELECT id, method, path, summary FROM endpoints LIMIT 10;
```

## Дополнительные возможности

### Повторная загрузка спецификации:

```bash
# С перезаписью (по умолчанию)
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://localhost:12001/openapi.json",
    "overwrite": true
  }'

# Без перезаписи
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://localhost:12001/openapi.json",
    "overwrite": false
  }'
```

### Мониторинг:

```bash
# Проверка здоровья системы
curl http://localhost:8080/health

# Статистика по сервисам
curl http://localhost:8080/api/v1/services | jq 'length'

# Статистика по endpoints
curl http://localhost:8080/api/v1/endpoints | jq 'length'
```

## Следующие шаги

1. Изучите созданные endpoints в базе данных
2. Попробуйте загрузить свои OpenAPI спецификации
3. Интегрируйте функционал в свои процессы CI/CD
4. Настройте автоматическое обновление спецификаций

## Поддержка

При возникновении проблем:

1. Проверьте логи: `docker-compose logs -f`
2. Убедитесь, что все сервисы запущены: `docker-compose ps`
3. Проверьте доступность портов: `netstat -tlnp | grep :8080`
4. Обратитесь к документации: `OPENAPI_LOADER_README.md`