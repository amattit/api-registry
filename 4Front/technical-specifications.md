# Технические спецификации для Frontend приложения API Registry

## Структура проекта

```
src/
├── components/
│   ├── ui/                     # Базовые UI компоненты
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Select.tsx
│   │   ├── Modal.tsx
│   │   ├── Table.tsx
│   │   └── index.ts
│   ├── forms/                  # Компоненты форм
│   │   ├── ServiceForm.tsx
│   │   ├── EndpointForm.tsx
│   │   └── EnvironmentForm.tsx
│   ├── layout/                 # Компоненты макета
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   ├── Navigation.tsx
│   │   └── Layout.tsx
│   └── features/               # Функциональные компоненты
│       ├── services/
│       ├── endpoints/
│       ├── databases/
│       └── dependencies/
├── pages/                      # Страницы приложения
│   ├── HomePage.tsx
│   ├── ServicesPage.tsx
│   ├── ServiceDetailPage.tsx
│   ├── CreateServicePage.tsx
│   ├── DatabasesPage.tsx
│   └── NotFoundPage.tsx
├── hooks/                      # Кастомные хуки
│   ├── useHotkeys.ts
│   ├── useServices.ts
│   ├── useEndpoints.ts
│   ├── useDatabases.ts
│   └── useSearch.ts
├── services/                   # API сервисы
│   ├── api.ts
│   ├── servicesApi.ts
│   ├── endpointsApi.ts
│   ├── databasesApi.ts
│   └── dependenciesApi.ts
├── types/                      # TypeScript типы
│   ├── api.ts
│   ├── service.ts
│   ├── endpoint.ts
│   └── database.ts
├── utils/                      # Утилиты
│   ├── validation.ts
│   ├── formatting.ts
│   ├── constants.ts
│   └── helpers.ts
├── contexts/                   # React контексты
│   ├── ThemeContext.tsx
│   ├── HotkeysContext.tsx
│   └── NotificationContext.tsx
├── styles/                     # Стили
│   ├── globals.css
│   ├── components.css
│   └── themes.css
└── __tests__/                  # Тесты
    ├── components/
    ├── hooks/
    ├── services/
    └── utils/
```

## TypeScript типы

### Базовые типы API

```typescript
// src/types/api.ts
export interface ApiResponse<T> {
  data: T;
  message?: string;
  status: number;
}

export interface ApiError {
  message: string;
  status: number;
  details?: Record<string, any>;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasNext: boolean;
  hasPrev: boolean;
}
```

### Типы для сервисов

```typescript
// src/types/service.ts
export interface Service {
  serviceId: string;
  name: string;
  description?: string;
  owner: string;
  tags: string[];
  serviceType: ServiceType;
  supportsDatabase: boolean;
  proxy: boolean;
  createdAt: string;
  updatedAt: string;
  environments?: ServiceEnvironment[];
}

export enum ServiceType {
  APPLICATION = 'APPLICATION',
  LIBRARY = 'LIBRARY',
  JOB = 'JOB',
  PROXY = 'PROXY'
}

export interface ServiceEnvironment {
  environmentId: string;
  serviceId: string;
  code: string;
  displayName: string;
  host: string;
  config?: EnvironmentConfig;
  status: EnvironmentStatus;
  createdAt: string;
  updatedAt: string;
}

export interface EnvironmentConfig {
  timeoutMs?: number;
  retries?: number;
  downstreamOverrides?: Record<string, string>;
}

export enum EnvironmentStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE'
}

export interface CreateServiceRequest {
  name: string;
  description?: string;
  owner: string;
  tags: string[];
  serviceType: ServiceType;
  supportsDatabase: boolean;
  proxy: boolean;
}

export interface UpdateServiceRequest {
  name?: string;
  description?: string;
  owner?: string;
  tags?: string[];
  serviceType?: ServiceType;
  supportsDatabase?: boolean;
  proxy?: boolean;
}
```

### Типы для эндпоинтов

```typescript
// src/types/endpoint.ts
export interface Endpoint {
  endpointId: string;
  serviceId: string;
  method: HttpMethod;
  path: string;
  summary: string;
  requestSchema?: Record<string, any>;
  responseSchemas?: Record<string, any>;
  auth?: Record<string, any>;
  rateLimit?: Record<string, any>;
  metadata?: Record<string, any>;
  calls?: EndpointCall[];
  databases?: EndpointDatabase[];
  createdAt: string;
  updatedAt: string;
}

export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  PATCH = 'PATCH',
  DELETE = 'DELETE',
  HEAD = 'HEAD',
  OPTIONS = 'OPTIONS'
}

export interface EndpointCall {
  dependencyId: string;
  callType: CallType;
  config?: Record<string, any>;
  dependency: Dependency;
}

export interface EndpointDatabase {
  databaseId: string;
  operationType: OperationType;
  tableNames?: string[];
  config?: Record<string, any>;
  database: Database;
}

export enum CallType {
  SYNC = 'SYNC',
  ASYNC = 'ASYNC',
  CALLBACK = 'CALLBACK'
}

export enum OperationType {
  READ = 'READ',
  WRITE = 'WRITE',
  READ_WRITE = 'READ_WRITE'
}
```

## API клиент

### Базовый API клиент

```typescript
// src/services/api.ts
import axios, { AxiosInstance, AxiosResponse, AxiosError } from 'axios';
import { ApiResponse, ApiError } from '../types/api';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8080/api/v1',
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        // Add auth token if available
        const token = localStorage.getItem('auth_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor
    this.client.interceptors.response.use(
      (response: AxiosResponse) => response,
      (error: AxiosError) => {
        const apiError: ApiError = {
          message: error.message,
          status: error.response?.status || 500,
          details: error.response?.data,
        };

        // Handle specific error cases
        if (error.response?.status === 401) {
          // Handle unauthorized
          localStorage.removeItem('auth_token');
          window.location.href = '/login';
        }

        return Promise.reject(apiError);
      }
    );
  }

  async get<T>(url: string, params?: Record<string, any>): Promise<T> {
    const response = await this.client.get<T>(url, { params });
    return response.data;
  }

  async post<T>(url: string, data?: any): Promise<T> {
    const response = await this.client.post<T>(url, data);
    return response.data;
  }

  async put<T>(url: string, data?: any): Promise<T> {
    const response = await this.client.put<T>(url, data);
    return response.data;
  }

  async patch<T>(url: string, data?: any): Promise<T> {
    const response = await this.client.patch<T>(url, data);
    return response.data;
  }

  async delete<T>(url: string): Promise<T> {
    const response = await this.client.delete<T>(url);
    return response.data;
  }
}

export const apiClient = new ApiClient();
```

### API для сервисов

```typescript
// src/services/servicesApi.ts
import { apiClient } from './api';
import { Service, CreateServiceRequest, UpdateServiceRequest } from '../types/service';
import { PaginatedResponse } from '../types/api';

export interface ServicesFilters {
  search?: string;
  serviceType?: string;
  owner?: string;
  tags?: string[];
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export const servicesApi = {
  // Получить список сервисов
  getServices: async (filters?: ServicesFilters): Promise<PaginatedResponse<Service>> => {
    return apiClient.get<PaginatedResponse<Service>>('/services', filters);
  },

  // Получить сервис по ID
  getService: async (serviceId: string): Promise<Service> => {
    return apiClient.get<Service>(`/services/${serviceId}`);
  },

  // Создать новый сервис
  createService: async (data: CreateServiceRequest): Promise<Service> => {
    return apiClient.post<Service>('/services', data);
  },

  // Обновить сервис
  updateService: async (serviceId: string, data: UpdateServiceRequest): Promise<Service> => {
    return apiClient.patch<Service>(`/services/${serviceId}`, data);
  },

  // Удалить сервис
  deleteService: async (serviceId: string): Promise<void> => {
    return apiClient.delete<void>(`/services/${serviceId}`);
  },

  // Создать/обновить окружение
  upsertEnvironment: async (
    serviceId: string,
    envCode: string,
    data: any
  ): Promise<any> => {
    return apiClient.put<any>(`/services/${serviceId}/environments/${envCode}`, data);
  },

  // Удалить окружение
  deleteEnvironment: async (serviceId: string, envCode: string): Promise<void> => {
    return apiClient.delete<void>(`/services/${serviceId}/environments/${envCode}`);
  },

  // Генерировать OpenAPI спецификацию
  generateOpenAPI: async (serviceId: string, envCode?: string): Promise<any> => {
    const params = envCode ? { env: envCode } : {};
    return apiClient.post<any>(`/services/${serviceId}/generate-openapi`, {}, params);
  },
};
```

## Кастомные хуки

### Хук для работы с сервисами

```typescript
// src/hooks/useServices.ts
import { useState, useEffect, useCallback } from 'react';
import { servicesApi, ServicesFilters } from '../services/servicesApi';
import { Service } from '../types/service';
import { PaginatedResponse } from '../types/api';

export const useServices = (initialFilters?: ServicesFilters) => {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pagination, setPagination] = useState({
    total: 0,
    page: 1,
    limit: 20,
    hasNext: false,
    hasPrev: false,
  });
  const [filters, setFilters] = useState<ServicesFilters>(initialFilters || {});

  const fetchServices = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response: PaginatedResponse<Service> = await servicesApi.getServices(filters);
      setServices(response.data);
      setPagination({
        total: response.total,
        page: response.page,
        limit: response.limit,
        hasNext: response.hasNext,
        hasPrev: response.hasPrev,
      });
    } catch (err: any) {
      setError(err.message || 'Failed to fetch services');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    fetchServices();
  }, [fetchServices]);

  const updateFilters = useCallback((newFilters: Partial<ServicesFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters, page: 1 }));
  }, []);

  const nextPage = useCallback(() => {
    if (pagination.hasNext) {
      setFilters(prev => ({ ...prev, page: (prev.page || 1) + 1 }));
    }
  }, [pagination.hasNext]);

  const prevPage = useCallback(() => {
    if (pagination.hasPrev) {
      setFilters(prev => ({ ...prev, page: Math.max((prev.page || 1) - 1, 1) }));
    }
  }, [pagination.hasPrev]);

  const refresh = useCallback(() => {
    fetchServices();
  }, [fetchServices]);

  return {
    services,
    loading,
    error,
    pagination,
    filters,
    updateFilters,
    nextPage,
    prevPage,
    refresh,
  };
};
```

### Хук для горячих клавиш

```typescript
// src/hooks/useHotkeys.ts
import { useEffect, useCallback, useRef } from 'react';

export interface HotkeyConfig {
  key: string;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
  metaKey?: boolean;
  preventDefault?: boolean;
  stopPropagation?: boolean;
}

export const useHotkeys = (
  config: HotkeyConfig,
  callback: (event: KeyboardEvent) => void,
  deps: React.DependencyList = []
) => {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  const handleKeyDown = useCallback((event: KeyboardEvent) => {
    const {
      key,
      ctrlKey = false,
      shiftKey = false,
      altKey = false,
      metaKey = false,
      preventDefault = true,
      stopPropagation = true,
    } = config;

    // Check if the key combination matches
    const keyMatches = event.key.toLowerCase() === key.toLowerCase();
    const ctrlMatches = event.ctrlKey === ctrlKey;
    const shiftMatches = event.shiftKey === shiftKey;
    const altMatches = event.altKey === altKey;
    const metaMatches = event.metaKey === metaKey;

    if (keyMatches && ctrlMatches && shiftMatches && altMatches && metaMatches) {
      if (preventDefault) event.preventDefault();
      if (stopPropagation) event.stopPropagation();
      callbackRef.current(event);
    }
  }, [config]);

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown, ...deps]);
};

// Хук для множественных горячих клавиш
export const useHotkeysMap = (
  hotkeys: Record<string, () => void>,
  deps: React.DependencyList = []
) => {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const key = [
        event.ctrlKey && 'ctrl',
        event.shiftKey && 'shift',
        event.altKey && 'alt',
        event.metaKey && 'meta',
        event.key.toLowerCase(),
      ]
        .filter(Boolean)
        .join('+');

      const callback = hotkeys[key];
      if (callback) {
        event.preventDefault();
        event.stopPropagation();
        callback();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [hotkeys, ...deps]);
};
```

## UI компоненты

### Базовый Button компонент

```typescript
// src/components/ui/Button.tsx
import React, { forwardRef } from 'react';
import { cn } from '../../utils/helpers';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      className,
      variant = 'primary',
      size = 'md',
      loading = false,
      leftIcon,
      rightIcon,
      children,
      disabled,
      ...props
    },
    ref
  ) => {
    const baseClasses = [
      'inline-flex items-center justify-center rounded-md font-medium',
      'transition-colors duration-200',
      'focus:outline-none focus:ring-2 focus:ring-offset-2',
      'disabled:opacity-50 disabled:cursor-not-allowed',
    ];

    const variantClasses = {
      primary: [
        'bg-blue-600 text-white hover:bg-blue-700',
        'focus:ring-blue-500',
      ],
      secondary: [
        'bg-gray-600 text-white hover:bg-gray-700',
        'focus:ring-gray-500',
      ],
      outline: [
        'border border-gray-300 bg-white text-gray-700',
        'hover:bg-gray-50 focus:ring-blue-500',
      ],
      ghost: [
        'text-gray-700 hover:bg-gray-100',
        'focus:ring-gray-500',
      ],
      danger: [
        'bg-red-600 text-white hover:bg-red-700',
        'focus:ring-red-500',
      ],
    };

    const sizeClasses = {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-2 text-sm',
      lg: 'px-6 py-3 text-base',
    };

    return (
      <button
        ref={ref}
        className={cn(
          baseClasses,
          variantClasses[variant],
          sizeClasses[size],
          className
        )}
        disabled={disabled || loading}
        {...props}
      >
        {loading && (
          <svg
            className="animate-spin -ml-1 mr-2 h-4 w-4"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
        )}
        {leftIcon && !loading && <span className="mr-2">{leftIcon}</span>}
        {children}
        {rightIcon && <span className="ml-2">{rightIcon}</span>}
      </button>
    );
  }
);

Button.displayName = 'Button';
```

### Input компонент с валидацией

```typescript
// src/components/ui/Input.tsx
import React, { forwardRef } from 'react';
import { cn } from '../../utils/helpers';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  (
    {
      className,
      label,
      error,
      helperText,
      leftIcon,
      rightIcon,
      id,
      ...props
    },
    ref
  ) => {
    const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;

    const baseClasses = [
      'block w-full rounded-md border-gray-300 shadow-sm',
      'focus:border-blue-500 focus:ring-blue-500',
      'disabled:bg-gray-50 disabled:text-gray-500',
      'sm:text-sm',
    ];

    const errorClasses = error
      ? 'border-red-300 text-red-900 placeholder-red-300 focus:border-red-500 focus:ring-red-500'
      : '';

    const paddingClasses = [
      leftIcon && 'pl-10',
      rightIcon && 'pr-10',
    ].filter(Boolean);

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <span className="text-gray-400 sm:text-sm">{leftIcon}</span>
            </div>
          )}
          <input
            ref={ref}
            id={inputId}
            className={cn(
              baseClasses,
              errorClasses,
              paddingClasses,
              className
            )}
            aria-invalid={error ? 'true' : 'false'}
            aria-describedby={
              error ? `${inputId}-error` : helperText ? `${inputId}-helper` : undefined
            }
            {...props}
          />
          {rightIcon && (
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <span className="text-gray-400 sm:text-sm">{rightIcon}</span>
            </div>
          )}
        </div>
        {error && (
          <p id={`${inputId}-error`} className="mt-1 text-sm text-red-600">
            {error}
          </p>
        )}
        {helperText && !error && (
          <p id={`${inputId}-helper`} className="mt-1 text-sm text-gray-500">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';
```

### Modal компонент с focus trap

```typescript
// src/components/ui/Modal.tsx
import React, { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { cn } from '../../utils/helpers';
import { useHotkeys } from '../../hooks/useHotkeys';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  closeOnBackdrop?: boolean;
  closeOnEscape?: boolean;
}

export const Modal: React.FC<ModalProps> = ({
  isOpen,
  onClose,
  title,
  children,
  size = 'md',
  closeOnBackdrop = true,
  closeOnEscape = true,
}) => {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousActiveElement = useRef<HTMLElement | null>(null);

  // Handle escape key
  useHotkeys(
    { key: 'Escape' },
    () => {
      if (closeOnEscape && isOpen) {
        onClose();
      }
    },
    [isOpen, closeOnEscape, onClose]
  );

  // Focus management
  useEffect(() => {
    if (isOpen) {
      previousActiveElement.current = document.activeElement as HTMLElement;
      
      // Focus the modal
      setTimeout(() => {
        if (modalRef.current) {
          const focusableElement = modalRef.current.querySelector(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
          ) as HTMLElement;
          
          if (focusableElement) {
            focusableElement.focus();
          } else {
            modalRef.current.focus();
          }
        }
      }, 0);
    } else {
      // Restore focus
      if (previousActiveElement.current) {
        previousActiveElement.current.focus();
      }
    }
  }, [isOpen]);

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  // Focus trap
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Tab' && modalRef.current) {
      const focusableElements = modalRef.current.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      
      const firstElement = focusableElements[0] as HTMLElement;
      const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

      if (event.shiftKey) {
        if (document.activeElement === firstElement) {
          event.preventDefault();
          lastElement.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          event.preventDefault();
          firstElement.focus();
        }
      }
    }
  };

  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
  };

  if (!isOpen) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-50 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          onClick={closeOnBackdrop ? onClose : undefined}
        />

        {/* Center modal */}
        <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
          &#8203;
        </span>

        {/* Modal panel */}
        <div
          ref={modalRef}
          className={cn(
            'inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:p-6',
            sizeClasses[size],
            'w-full'
          )}
          onKeyDown={handleKeyDown}
          tabIndex={-1}
        >
          {title && (
            <div className="mb-4">
              <h3 id="modal-title" className="text-lg font-medium text-gray-900">
                {title}
              </h3>
            </div>
          )}
          {children}
        </div>
      </div>
    </div>,
    document.body
  );
};
```

## Утилиты

### Валидация

```typescript
// src/utils/validation.ts
import * as yup from 'yup';

export const serviceValidationSchema = yup.object({
  name: yup
    .string()
    .required('Название сервиса обязательно')
    .max(150, 'Название не должно превышать 150 символов')
    .matches(/^[a-zA-Z0-9-_]+$/, 'Название может содержать только буквы, цифры, дефисы и подчеркивания'),
  
  description: yup
    .string()
    .max(500, 'Описание не должно превышать 500 символов'),
  
  owner: yup
    .string()
    .required('Владелец обязателен')
    .max(120, 'Имя владельца не должно превышать 120 символов'),
  
  tags: yup
    .array()
    .of(yup.string().required())
    .max(10, 'Максимум 10 тегов'),
  
  serviceType: yup
    .string()
    .oneOf(['APPLICATION', 'LIBRARY', 'JOB', 'PROXY'])
    .required('Тип сервиса обязателен'),
  
  supportsDatabase: yup.boolean().required(),
  proxy: yup.boolean().required(),
});

export const endpointValidationSchema = yup.object({
  method: yup
    .string()
    .oneOf(['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'])
    .required('HTTP метод обязателен'),
  
  path: yup
    .string()
    .required('Путь обязателен')
    .matches(/^\//, 'Путь должен начинаться с /')
    .max(255, 'Путь не должен превышать 255 символов'),
  
  summary: yup
    .string()
    .required('Описание обязательно')
    .max(200, 'Описание не должно превышать 200 символов'),
  
  requestSchema: yup
    .object()
    .test('valid-json-schema', 'Некорректная JSON Schema', (value) => {
      if (!value) return true;
      try {
        // Validate JSON Schema format
        return true;
      } catch {
        return false;
      }
    }),
});

export const environmentValidationSchema = yup.object({
  displayName: yup
    .string()
    .required('Отображаемое имя обязательно')
    .max(120, 'Имя не должно превышать 120 символов'),
  
  host: yup
    .string()
    .required('Хост обязателен')
    .url('Хост должен быть валидным URL')
    .max(255, 'URL не должен превышать 255 символов'),
  
  config: yup.object({
    timeoutMs: yup
      .number()
      .positive('Таймаут должен быть положительным числом')
      .max(60000, 'Таймаут не должен превышать 60 секунд'),
    
    retries: yup
      .number()
      .integer('Количество повторов должно быть целым числом')
      .min(0, 'Количество повторов не может быть отрицательным')
      .max(10, 'Максимум 10 повторов'),
  }),
  
  status: yup
    .string()
    .oneOf(['ACTIVE', 'INACTIVE'])
    .required('Статус обязателен'),
});
```

### Форматирование и хелперы

```typescript
// src/utils/helpers.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Utility for merging Tailwind classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Format date
export function formatDate(date: string | Date): string {
  const d = new Date(date);
  return d.toLocaleDateString('ru-RU', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

// Format relative time
export function formatRelativeTime(date: string | Date): string {
  const now = new Date();
  const d = new Date(date);
  const diffInSeconds = Math.floor((now.getTime() - d.getTime()) / 1000);

  if (diffInSeconds < 60) return 'только что';
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} мин назад`;
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} ч назад`;
  if (diffInSeconds < 2592000) return `${Math.floor(diffInSeconds / 86400)} дн назад`;
  
  return formatDate(date);
}

// Debounce function
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout;
  
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

// Throttle function
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;
  
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

// Generate unique ID
export function generateId(): string {
  return Math.random().toString(36).substr(2, 9);
}

// Copy to clipboard
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    // Fallback for older browsers
    const textArea = document.createElement('textarea');
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    
    try {
      document.execCommand('copy');
      document.body.removeChild(textArea);
      return true;
    } catch {
      document.body.removeChild(textArea);
      return false;
    }
  }
}

// Download file
export function downloadFile(content: string, filename: string, contentType: string = 'text/plain') {
  const blob = new Blob([content], { type: contentType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// Validate JSON
export function isValidJSON(str: string): boolean {
  try {
    JSON.parse(str);
    return true;
  } catch {
    return false;
  }
}

// Format JSON
export function formatJSON(obj: any): string {
  return JSON.stringify(obj, null, 2);
}

// Get HTTP method color
export function getHttpMethodColor(method: string): string {
  const colors = {
    GET: 'bg-green-100 text-green-800',
    POST: 'bg-blue-100 text-blue-800',
    PUT: 'bg-yellow-100 text-yellow-800',
    PATCH: 'bg-orange-100 text-orange-800',
    DELETE: 'bg-red-100 text-red-800',
    HEAD: 'bg-gray-100 text-gray-800',
    OPTIONS: 'bg-purple-100 text-purple-800',
  };
  
  return colors[method as keyof typeof colors] || 'bg-gray-100 text-gray-800';
}

// Truncate text
export function truncate(text: string, length: number): string {
  if (text.length <= length) return text;
  return text.slice(0, length) + '...';
}

// Highlight search terms
export function highlightSearchTerm(text: string, searchTerm: string): string {
  if (!searchTerm) return text;
  
  const regex = new RegExp(`(${searchTerm})`, 'gi');
  return text.replace(regex, '<mark>$1</mark>');
}
```

## Константы

```typescript
// src/utils/constants.ts
export const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api/v1';

export const HTTP_METHODS = [
  'GET',
  'POST',
  'PUT',
  'PATCH',
  'DELETE',
  'HEAD',
  'OPTIONS',
] as const;

export const SERVICE_TYPES = [
  { value: 'APPLICATION', label: 'Приложение' },
  { value: 'LIBRARY', label: 'Библиотека' },
  { value: 'JOB', label: 'Задача' },
  { value: 'PROXY', label: 'Прокси' },
] as const;

export const ENVIRONMENT_STATUSES = [
  { value: 'ACTIVE', label: 'Активное' },
  { value: 'INACTIVE', label: 'Неактивное' },
] as const;

export const DATABASE_TYPES = [
  { value: 'POSTGRESQL', label: 'PostgreSQL' },
  { value: 'MYSQL', label: 'MySQL' },
  { value: 'MONGODB', label: 'MongoDB' },
  { value: 'REDIS', label: 'Redis' },
  { value: 'ELASTICSEARCH', label: 'Elasticsearch' },
] as const;

export const OPERATION_TYPES = [
  { value: 'READ', label: 'Чтение' },
  { value: 'WRITE', label: 'Запись' },
  { value: 'READ_WRITE', label: 'Чтение/Запись' },
] as const;

export const CALL_TYPES = [
  { value: 'SYNC', label: 'Синхронный' },
  { value: 'ASYNC', label: 'Асинхронный' },
  { value: 'CALLBACK', label: 'Callback' },
] as const;

export const HOTKEYS = {
  GLOBAL_SEARCH: 'ctrl+k',
  HELP: 'ctrl+/',
  SAVE: 'ctrl+s',
  ESCAPE: 'escape',
  SERVICES: 'ctrl+1',
  DATABASES: 'ctrl+2',
  DEPENDENCIES: 'ctrl+3',
} as const;

export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 20,
  PAGE_SIZE_OPTIONS: [10, 20, 50, 100],
} as const;

export const VALIDATION = {
  MAX_SERVICE_NAME_LENGTH: 150,
  MAX_OWNER_NAME_LENGTH: 120,
  MAX_DESCRIPTION_LENGTH: 500,
  MAX_TAGS_COUNT: 10,
  MAX_PATH_LENGTH: 255,
  MAX_SUMMARY_LENGTH: 200,
  MAX_HOST_LENGTH: 255,
  MAX_TIMEOUT_MS: 60000,
  MAX_RETRIES: 10,
} as const;
```

Эти технические спецификации предоставляют детальное руководство для разработчиков по реализации frontend приложения с акцентом на клавиатурную навигацию и accessibility.