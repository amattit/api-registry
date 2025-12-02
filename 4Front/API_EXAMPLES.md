# Примеры использования API

## JavaScript/TypeScript примеры

### 1. Создание HTTP клиента

```typescript
// api/client.ts
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Перехватчик для обработки ошибок
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);
```

### 2. Сервис для работы с зависимостями между сервисами

```typescript
// services/serviceDependencyService.ts
import { apiClient } from './client';

export interface ServiceDependency {
  id: string;
  consumerService: ServiceSummary;
  providerService: ServiceSummary;
  environmentCode?: string;
  description?: string;
  dependencyType: ServiceDependencyType;
  config: Record<string, string>;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateServiceDependencyRequest {
  providerServiceId: string;
  environmentCode?: string;
  description?: string;
  dependencyType: ServiceDependencyType;
  config: Record<string, string>;
}

export type ServiceDependencyType = 
  | 'API_CALL'
  | 'EVENT_SUBSCRIPTION'
  | 'DATA_SHARING'
  | 'AUTHENTICATION'
  | 'PROXY'
  | 'LIBRARY_USAGE';

export const serviceDependencyService = {
  // Создание зависимости
  async createDependency(
    consumerServiceId: string, 
    data: CreateServiceDependencyRequest
  ): Promise<ServiceDependency> {
    const response = await apiClient.post(
      `/services/${consumerServiceId}/service-dependencies`,
      data
    );
    return response.data;
  },

  // Получение зависимостей сервиса
  async getDependencies(
    serviceId: string, 
    environmentCode?: string
  ): Promise<ServiceDependency[]> {
    const params = environmentCode ? { environmentCode } : {};
    const response = await apiClient.get(
      `/services/${serviceId}/service-dependencies`,
      { params }
    );
    return response.data;
  },

  // Обновление зависимости
  async updateDependency(
    serviceId: string,
    dependencyId: string,
    data: Partial<CreateServiceDependencyRequest>
  ): Promise<ServiceDependency> {
    const response = await apiClient.patch(
      `/services/${serviceId}/service-dependencies/${dependencyId}`,
      data
    );
    return response.data;
  },

  // Удаление зависимости
  async deleteDependency(
    serviceId: string,
    dependencyId: string
  ): Promise<void> {
    await apiClient.delete(
      `/services/${serviceId}/service-dependencies/${dependencyId}`
    );
  },

  // Получение графа зависимостей
  async getDependencyGraph(
    serviceId: string,
    environmentCode?: string
  ): Promise<ServiceDependencyGraph> {
    const params = environmentCode ? { environmentCode } : {};
    const response = await apiClient.get(
      `/services/${serviceId}/dependency-graph`,
      { params }
    );
    return response.data;
  },

  // Глобальный граф зависимостей
  async getGlobalDependencyGraph(
    environmentCode?: string
  ): Promise<ServiceDependency[]> {
    const params = environmentCode ? { environmentCode } : {};
    const response = await apiClient.get('/dependency-graph', { params });
    return response.data;
  }
};
```

### 3. React Hook для управления зависимостями

```typescript
// hooks/useServiceDependencies.ts
import { useState, useEffect } from 'react';
import { serviceDependencyService, ServiceDependency } from '../services/serviceDependencyService';

export const useServiceDependencies = (serviceId: string, environmentCode?: string) => {
  const [dependencies, setDependencies] = useState<ServiceDependency[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadDependencies = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await serviceDependencyService.getDependencies(serviceId, environmentCode);
      setDependencies(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load dependencies');
    } finally {
      setLoading(false);
    }
  };

  const createDependency = async (data: CreateServiceDependencyRequest) => {
    try {
      const newDependency = await serviceDependencyService.createDependency(serviceId, data);
      setDependencies(prev => [...prev, newDependency]);
      return newDependency;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create dependency');
      throw err;
    }
  };

  const deleteDependency = async (dependencyId: string) => {
    try {
      await serviceDependencyService.deleteDependency(serviceId, dependencyId);
      setDependencies(prev => prev.filter(dep => dep.id !== dependencyId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete dependency');
      throw err;
    }
  };

  useEffect(() => {
    if (serviceId) {
      loadDependencies();
    }
  }, [serviceId, environmentCode]);

  return {
    dependencies,
    loading,
    error,
    createDependency,
    deleteDependency,
    refetch: loadDependencies
  };
};
```

### 4. React компонент для создания зависимости

```typescript
// components/CreateServiceDependencyForm.tsx
import React, { useState } from 'react';
import { useServiceDependencies } from '../hooks/useServiceDependencies';

interface Props {
  consumerServiceId: string;
  onSuccess?: () => void;
  onCancel?: () => void;
}

export const CreateServiceDependencyForm: React.FC<Props> = ({
  consumerServiceId,
  onSuccess,
  onCancel
}) => {
  const { createDependency } = useServiceDependencies(consumerServiceId);
  const [formData, setFormData] = useState({
    providerServiceId: '',
    environmentCode: '',
    description: '',
    dependencyType: 'API_CALL' as ServiceDependencyType,
    config: {} as Record<string, string>
  });
  const [configEntries, setConfigEntries] = useState([{ key: '', value: '' }]);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      
      // Собираем конфигурацию из пар ключ-значение
      const config = configEntries.reduce((acc, entry) => {
        if (entry.key && entry.value) {
          acc[entry.key] = entry.value;
        }
        return acc;
      }, {} as Record<string, string>);

      await createDependency({
        ...formData,
        config
      });
      
      onSuccess?.();
    } catch (error) {
      console.error('Failed to create dependency:', error);
    } finally {
      setLoading(false);
    }
  };

  const addConfigEntry = () => {
    setConfigEntries([...configEntries, { key: '', value: '' }]);
  };

  const removeConfigEntry = (index: number) => {
    setConfigEntries(configEntries.filter((_, i) => i !== index));
  };

  const updateConfigEntry = (index: number, field: 'key' | 'value', value: string) => {
    const updated = [...configEntries];
    updated[index][field] = value;
    setConfigEntries(updated);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="providerServiceId" className="block text-sm font-medium">
          Сервис-провайдер *
        </label>
        <select
          id="providerServiceId"
          value={formData.providerServiceId}
          onChange={(e) => setFormData({ ...formData, providerServiceId: e.target.value })}
          required
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        >
          <option value="">Выберите сервис</option>
          {/* Здесь должен быть список доступных сервисов */}
        </select>
      </div>

      <div>
        <label htmlFor="dependencyType" className="block text-sm font-medium">
          Тип зависимости *
        </label>
        <select
          id="dependencyType"
          value={formData.dependencyType}
          onChange={(e) => setFormData({ ...formData, dependencyType: e.target.value as ServiceDependencyType })}
          required
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        >
          <option value="API_CALL">API вызов</option>
          <option value="EVENT_SUBSCRIPTION">Подписка на события</option>
          <option value="DATA_SHARING">Совместное использование данных</option>
          <option value="AUTHENTICATION">Аутентификация</option>
          <option value="PROXY">Прокси</option>
          <option value="LIBRARY_USAGE">Использование библиотеки</option>
        </select>
      </div>

      <div>
        <label htmlFor="environmentCode" className="block text-sm font-medium">
          Окружение
        </label>
        <input
          type="text"
          id="environmentCode"
          value={formData.environmentCode}
          onChange={(e) => setFormData({ ...formData, environmentCode: e.target.value })}
          placeholder="production, staging, development"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        />
      </div>

      <div>
        <label htmlFor="description" className="block text-sm font-medium">
          Описание
        </label>
        <textarea
          id="description"
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        />
      </div>

      <div>
        <label className="block text-sm font-medium mb-2">Конфигурация</label>
        {configEntries.map((entry, index) => (
          <div key={index} className="flex space-x-2 mb-2">
            <input
              type="text"
              placeholder="Ключ"
              value={entry.key}
              onChange={(e) => updateConfigEntry(index, 'key', e.target.value)}
              className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
            <input
              type="text"
              placeholder="Значение"
              value={entry.value}
              onChange={(e) => updateConfigEntry(index, 'value', e.target.value)}
              className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
            <button
              type="button"
              onClick={() => removeConfigEntry(index)}
              className="px-3 py-2 text-red-600 hover:text-red-800"
            >
              Удалить
            </button>
          </div>
        ))}
        <button
          type="button"
          onClick={addConfigEntry}
          className="text-indigo-600 hover:text-indigo-800"
        >
          + Добавить параметр
        </button>
      </div>

      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
        >
          Отмена
        </button>
        <button
          type="submit"
          disabled={loading}
          className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 disabled:opacity-50"
        >
          {loading ? 'Создание...' : 'Создать зависимость'}
        </button>
      </div>
    </form>
  );
};
```

### 5. Обработка ошибок

```typescript
// utils/errorHandler.ts
export const handleApiError = (error: any) => {
  if (error.response) {
    const { status, data } = error.response;
    
    switch (status) {
      case 400:
        return `Неверный запрос: ${data.reason || 'Проверьте введенные данные'}`;
      case 404:
        return 'Ресурс не найден';
      case 409:
        return `Конфликт: ${data.reason || 'Данные уже существуют'}`;
      case 500:
        return 'Внутренняя ошибка сервера';
      default:
        return `Ошибка ${status}: ${data.reason || 'Неизвестная ошибка'}`;
    }
  }
  
  if (error.request) {
    return 'Нет ответа от сервера. Проверьте подключение к интернету.';
  }
  
  return error.message || 'Произошла неизвестная ошибка';
};
```

### 6. Пример использования с Redux Toolkit

```typescript
// store/serviceDependencySlice.ts
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { serviceDependencyService, ServiceDependency } from '../services/serviceDependencyService';

interface ServiceDependencyState {
  dependencies: ServiceDependency[];
  loading: boolean;
  error: string | null;
}

const initialState: ServiceDependencyState = {
  dependencies: [],
  loading: false,
  error: null,
};

export const fetchServiceDependencies = createAsyncThunk(
  'serviceDependency/fetchDependencies',
  async ({ serviceId, environmentCode }: { serviceId: string; environmentCode?: string }) => {
    return await serviceDependencyService.getDependencies(serviceId, environmentCode);
  }
);

export const createServiceDependency = createAsyncThunk(
  'serviceDependency/createDependency',
  async ({ serviceId, data }: { serviceId: string; data: CreateServiceDependencyRequest }) => {
    return await serviceDependencyService.createDependency(serviceId, data);
  }
);

const serviceDependencySlice = createSlice({
  name: 'serviceDependency',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchServiceDependencies.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchServiceDependencies.fulfilled, (state, action) => {
        state.loading = false;
        state.dependencies = action.payload;
      })
      .addCase(fetchServiceDependencies.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to fetch dependencies';
      })
      .addCase(createServiceDependency.fulfilled, (state, action) => {
        state.dependencies.push(action.payload);
      });
  },
});

export default serviceDependencySlice.reducer;
```

## Примеры cURL запросов

### Создание зависимости между сервисами
```bash
curl -X POST http://localhost:8080/api/v1/services/123e4567-e89b-12d3-a456-426614174000/service-dependencies \
  -H "Content-Type: application/json" \
  -d '{
    "providerServiceId": "987fcdeb-51a2-43d1-b456-426614174111",
    "environmentCode": "production",
    "description": "Authentication service dependency",
    "dependencyType": "API_CALL",
    "config": {
      "endpoint": "https://auth.example.com/api/v1",
      "timeout": "30s",
      "retries": "3"
    }
  }'
```

### Получение зависимостей сервиса
```bash
curl -X GET "http://localhost:8080/api/v1/services/123e4567-e89b-12d3-a456-426614174000/service-dependencies?environmentCode=production"
```

### Получение графа зависимостей
```bash
curl -X GET "http://localhost:8080/api/v1/services/123e4567-e89b-12d3-a456-426614174000/dependency-graph?environmentCode=production"
```

### Глобальный граф зависимостей
```bash
curl -X GET "http://localhost:8080/api/v1/dependency-graph?environmentCode=production"
```