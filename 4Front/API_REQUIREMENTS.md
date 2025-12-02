# API Registry Frontend - Требования к реализации

## Общие требования

### Доступность и управление с клавиатуры
**КРИТИЧЕСКИ ВАЖНО**: Приложение должно обеспечивать минимальное взаимодействие с мышкой/трекпадом. Большинство действий должно быть доступно с клавиатуры.

#### Обязательные горячие клавиши:
- `Tab` / `Shift+Tab` - навигация между элементами
- `Enter` - активация кнопок и ссылок
- `Space` - выбор чекбоксов и переключателей
- `Escape` - закрытие модальных окон и выпадающих меню
- `Arrow Keys` - навигация в списках и таблицах
- `Ctrl+S` - сохранение форм
- `Ctrl+N` - создание нового элемента
- `Ctrl+E` - редактирование выбранного элемента
- `Delete` - удаление выбранного элемента
- `Ctrl+F` - поиск
- `F5` - обновление данных

#### Визуальные индикаторы:
- Четкое выделение фокуса на всех интерактивных элементах
- Индикаторы загрузки для асинхронных операций
- Уведомления об успешных/неуспешных операциях

## API Endpoints

### Базовый URL
```
http://localhost:8080/api/v1
```

### 1. Управление сервисами

#### 1.1 Получение списка сервисов
```http
GET /services
```

**Query Parameters:**
- `page` (optional) - номер страницы
- `limit` (optional) - количество элементов на странице
- `search` (optional) - поиск по имени или описанию
- `serviceType` (optional) - фильтр по типу сервиса
- `owner` (optional) - фильтр по владельцу

**Response:**
```json
{
  "services": [
    {
      "id": "uuid",
      "name": "string",
      "description": "string",
      "owner": "string",
      "serviceType": "API|LIBRARY|DATABASE|QUEUE|CACHE|STORAGE|EXTERNAL_API",
      "tags": ["string"],
      "supportsDatabase": boolean,
      "proxy": boolean,
      "createdAt": "datetime",
      "updatedAt": "datetime"
    }
  ],
  "pagination": {
    "page": number,
    "limit": number,
    "total": number,
    "totalPages": number
  }
}
```

#### 1.2 Создание сервиса
```http
POST /services
```

**Request Body:**
```json
{
  "name": "string",
  "description": "string",
  "owner": "string",
  "serviceType": "API|LIBRARY|DATABASE|QUEUE|CACHE|STORAGE|EXTERNAL_API",
  "tags": ["string"],
  "supportsDatabase": boolean,
  "proxy": boolean
}
```

#### 1.3 Получение сервиса по ID
```http
GET /services/{serviceId}
```

#### 1.4 Обновление сервиса
```http
PATCH /services/{serviceId}
```

#### 1.5 Удаление сервиса
```http
DELETE /services/{serviceId}
```

### 2. Управление зависимостями между сервисами (НОВОЕ)

#### 2.1 Создание зависимости между сервисами
```http
POST /services/{consumerServiceId}/service-dependencies
```

**Request Body:**
```json
{
  "providerServiceId": "uuid",
  "environmentCode": "string (optional)",
  "description": "string (optional)",
  "dependencyType": "API_CALL|EVENT_SUBSCRIPTION|DATA_SHARING|AUTHENTICATION|PROXY|LIBRARY_USAGE",
  "config": {
    "key": "value"
  }
}
```

**Response:**
```json
{
  "id": "uuid",
  "consumerService": {
    "id": "uuid",
    "name": "string",
    "description": "string",
    "serviceType": "string",
    "owner": "string"
  },
  "providerService": {
    "id": "uuid",
    "name": "string",
    "description": "string",
    "serviceType": "string",
    "owner": "string"
  },
  "environmentCode": "string",
  "description": "string",
  "dependencyType": "string",
  "config": {},
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

#### 2.2 Получение зависимостей сервиса
```http
GET /services/{serviceId}/service-dependencies
```

**Query Parameters:**
- `environmentCode` (optional) - фильтр по окружению

#### 2.3 Обновление зависимости
```http
PATCH /services/{serviceId}/service-dependencies/{dependencyId}
```

#### 2.4 Удаление зависимости
```http
DELETE /services/{serviceId}/service-dependencies/{dependencyId}
```

### 3. Граф зависимостей (НОВОЕ)

#### 3.1 Получение графа зависимостей для сервиса
```http
GET /services/{serviceId}/dependency-graph
```

**Query Parameters:**
- `environmentCode` (optional) - фильтр по окружению

**Response:**
```json
{
  "serviceId": "uuid",
  "serviceName": "string",
  "dependencies": [
    {
      "id": "uuid",
      "consumerService": {...},
      "providerService": {...},
      "dependencyType": "string",
      "environmentCode": "string"
    }
  ],
  "dependents": [
    {
      "id": "uuid",
      "consumerService": {...},
      "providerService": {...},
      "dependencyType": "string",
      "environmentCode": "string"
    }
  ]
}
```

#### 3.2 Получение глобального графа зависимостей
```http
GET /dependency-graph
```

**Query Parameters:**
- `environmentCode` (optional) - фильтр по окружению

### 4. Управление внешними зависимостями

#### 4.1 Получение списка зависимостей
```http
GET /dependencies
```

#### 4.2 Создание зависимости
```http
POST /dependencies
```

**Request Body:**
```json
{
  "name": "string",
  "type": "DATABASE|CACHE|QUEUE|STORAGE|EXTERNAL_API|LIBRARY|SERVICE",
  "description": "string",
  "config": {}
}
```

### 5. Управление базами данных

#### 5.1 Получение списка баз данных
```http
GET /databases
```

#### 5.2 Создание базы данных
```http
POST /databases
```

### 6. Управление endpoints

#### 6.1 Получение endpoints сервиса
```http
GET /services/{serviceId}/endpoints
```

#### 6.2 Создание endpoint
```http
POST /services/{serviceId}/endpoints
```

## Требования к UI компонентам

### 1. Главная страница (Dashboard)
- Обзор всех сервисов с возможностью быстрого поиска
- Статистика по типам сервисов
- Последние изменения
- Быстрые действия (создать сервис, просмотреть граф зависимостей)

### 2. Список сервисов
- Таблица с сортировкой и фильтрацией
- Поиск в реальном времени
- Пагинация
- Массовые операции (выбор через Ctrl+Click, Space)

### 3. Детальная страница сервиса
- Основная информация о сервисе
- Вкладки:
  - **Общая информация**
  - **Зависимости сервисов** (новая вкладка)
  - **Внешние зависимости**
  - **Endpoints**
  - **Базы данных**
  - **Граф зависимостей** (новая вкладка)

### 4. Управление зависимостями между сервисами (НОВОЕ)
- Форма создания зависимости с автокомплитом для выбора сервиса-провайдера
- Список существующих зависимостей с возможностью редактирования
- Фильтрация по окружению
- Валидация на предотвращение циклических зависимостей

### 5. Визуализация графа зависимостей (НОВОЕ)
- Интерактивный граф с возможностью навигации с клавиатуры
- Фильтрация по окружению
- Возможность фокусировки на конкретном сервисе
- Легенда типов зависимостей
- Экспорт графа в различные форматы

### 6. Формы создания/редактирования
- Валидация в реальном времени
- Автосохранение черновиков
- Подтверждение перед удалением
- Отмена изменений (Escape)

## Технические требования

### Стек технологий (рекомендуемый)
- **Frontend Framework**: React 18+ или Vue 3+
- **State Management**: Redux Toolkit / Zustand / Pinia
- **UI Library**: Material-UI / Ant Design / Chakra UI (с хорошей поддержкой клавиатуры)
- **HTTP Client**: Axios / Fetch API
- **Routing**: React Router / Vue Router
- **Graph Visualization**: D3.js / Cytoscape.js / Vis.js
- **Form Handling**: React Hook Form / VeeValidate
- **Testing**: Jest + React Testing Library / Vitest + Vue Testing Library

### Архитектура
- Модульная архитектура с разделением по доменам
- Переиспользуемые компоненты
- Централизованное управление состоянием
- Обработка ошибок на всех уровнях
- Кэширование данных

### Производительность
- Ленивая загрузка компонентов
- Виртуализация больших списков
- Дебаунсинг для поиска
- Оптимизация ререндеров

### Безопасность
- Валидация данных на клиенте и сервере
- Санитизация пользовательского ввода
- HTTPS для всех запросов
- Обработка CORS

## Пользовательский опыт

### Навигация
- Хлебные крошки на всех страницах
- Боковое меню с основными разделами
- Быстрый поиск в шапке приложения

### Обратная связь
- Уведомления об успешных операциях
- Детальные сообщения об ошибках
- Индикаторы загрузки
- Подтверждения для критических действий

### Адаптивность
- Поддержка различных разрешений экрана
- Мобильная версия (опционально)
- Темная/светлая тема

## Интеграция с API

### Обработка ошибок
```javascript
// Пример обработки ошибок
const handleApiError = (error) => {
  if (error.response?.status === 404) {
    showNotification('Ресурс не найден', 'error');
  } else if (error.response?.status === 409) {
    showNotification('Конфликт данных', 'warning');
  } else {
    showNotification('Произошла ошибка', 'error');
  }
};
```

### Кэширование
- Кэширование списков сервисов
- Инвалидация кэша при изменениях
- Оптимистичные обновления

### Состояние загрузки
```javascript
// Пример состояний
const [loading, setLoading] = useState(false);
const [error, setError] = useState(null);
const [data, setData] = useState(null);
```

## Дополнительные возможности

### Экспорт данных
- Экспорт списка сервисов в CSV/Excel
- Экспорт графа зависимостей в PNG/SVG
- Экспорт конфигурации в JSON

### Импорт данных
- Массовый импорт сервисов из CSV
- Импорт конфигурации из JSON

### Уведомления
- Уведомления о изменениях в зависимостях
- Предупреждения о циклических зависимостях
- Уведомления об устаревших зависимостях

## Метрики и аналитика

### Отслеживание использования
- Количество созданных сервисов
- Популярные типы зависимостей
- Активность пользователей

### Мониторинг производительности
- Время загрузки страниц
- Время отклика API
- Ошибки JavaScript

## Тестирование

### Unit тесты
- Тестирование компонентов
- Тестирование утилит и хелперов
- Тестирование состояния приложения

### Integration тесты
- Тестирование взаимодействия с API
- Тестирование пользовательских сценариев
- Тестирование навигации

### E2E тесты
- Критические пользовательские пути
- Тестирование доступности
- Кроссбраузерное тестирование

## Развертывание

### Сборка
- Минификация и оптимизация
- Разделение кода (code splitting)
- Генерация source maps для отладки

### Окружения
- Development
- Staging  
- Production

### CI/CD
- Автоматическая сборка при коммитах
- Автоматическое тестирование
- Автоматическое развертывание