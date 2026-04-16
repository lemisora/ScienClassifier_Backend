# ScienClassifier (Backend)

Este repositorio contiene el backend de un sistema de almacenamiento distribuido orientado al análisis de artículos científicos.

## Descripción General

El sistema utiliza una arquitectura de microservicios containerizada con Docker, diseñada para escalar horizontalmente según la demanda de procesamiento.

## Estructura del Proyecto

```
ScienClassifier_Backend/
├── docker-compose.yml        # Orquestación de contenedores Docker
├── main.py                   # Punto de entrada principal para la API de la aplicación
├── requirements.txt          # Dependencias de Python
├── LICENSE                   # Licencia del proyecto (aún por definir)
├── app/                      # Aplicación principal (API FastAPI)
│   ├── api/                  # Definición de endpoints de la API
│   │   └── endpoints.py      # Rutas y controladores de la API
│   ├── core/                 # Funcionalidades centrales del sistema
│   │   └── jwt_connections.py # Gestión de autenticación JWT
│   ├── db/                   # Configuración de base de datos
│   │   └── sql_connections.py # Conexiones y modelos SQL
│   └── services/             # Servicios externos integrados
│       ├── minio_connection.py   # Cliente para almacenamiento de objetos (MinIO/S3)
│       └── rabbitmq_connection.py # Productor de mensajes para cola RabbitMQ
├── worker/                   # Procesamiento asíncrono de artículos
│   ├── classifier.py         # Lógica de clasificación de artículos
│   └── rbmq_consumer.py      # Consumidor de mensajes desde RabbitMQ
└── nginx/                    # Configuración del servidor HTTP
    └── nginx.conf            # Configuración de proxy reverso y balanceador de carga
```

## Componentes

### `app/` - Aplicación Principal
Contiene la API REST desarrollada con FastAPI que expone los endpoints para:
- Gestión de artículos científicos
- Autenticación de usuarios mediante JWT
- Operaciones de almacenamiento y recuperación de archivos

### `app/api/endpoints.py`
Define las rutas HTTP disponibles y los controladores que procesan las solicitudes de los clientes.

### `app/core/jwt_connections.py`
Módulo encargado de la autenticación y autorización mediante tokens JWT (JSON Web Tokens).

### `app/db/sql_connections.py`
Gestiona las conexiones a la base de datos SQL, incluyendo modelos de datos y operaciones CRUD.

### `app/services/`
Integraciones con servicios externos:

- **minio_connection.py**: Cliente para MinIO (almacenamiento de objetos compatible con S3)
- **rabbitmq_connection.py**: Productor de mensajes para enviar tareas de procesamiento a la cola

### `worker/` - Workers de Procesamiento
Componentes para el procesamiento asíncrono:

- **classifier.py**: Implementa la lógica de clasificación de artículos científicos
- **rbmq_consumer.py**: Escucha la cola de mensajes y procesa las tareas enviadas por la API

### `nginx/`
Configuración del servidor nginx para que funja como:
- Proxy reverso para la API
- Balanceador de carga
- Terminal SSL (HTTPS)

### `docker-compose.yml`
Orquestación de todos los contenedores Docker:
- Contenedor de la API FastAPI
- Contenedor del worker
- Contenedor de nginx
- Contenedor de MinIO
- Contenedor de RabbitMQ
- Contenedor de la base de datos PostgreSQL

## Tecnologías Utilizadas

- **Python 3.x**: Lenguaje principal
- **FastAPI**: Framework web de alto rendimiento
- **Docker**: Containerización
- **nginx**: Servidor HTTP y balanceador de carga
- **RabbitMQ**: Sistema de mensajería asíncrona
- **MinIO**: Almacenamiento de objetos distribuido
- **SQL**: Base de datos relacional
- **JWT**: Autenticación stateless

## Despliegue

Para levantar el entorno de desarrollo:

```bash
docker-compose up --build
```

Para escalar workers:

```bash
docker-compose up --scale worker=N
```

## Requisitos

Ver `requirements.txt` para las dependencias de Python necesarias.
