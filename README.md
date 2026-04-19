# ScienClassifier (Backend)

Este repositorio contiene el backend de un sistema de almacenamiento distribuido orientado al análisis de artículos científicos.

## Descripción General

El sistema utiliza una arquitectura de microservicios **simétrica**: las 3 máquinas del clúster corren exactamente los mismos servicios. No hay nodo especial ni punto único de falla. La orquestación se hace con **Docker Swarm** usando un único `stack.yml` desplegado desde cualquier manager.

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
- **Docker Swarm**: Orquestación multi-nodo (reemplaza Docker Compose)
- **Nginx**: Sirve el frontend Angular compilado + hace proxy de `/api` a FastAPI
- **RabbitMQ**: Cluster de mensajería asíncrona (3 nodos)
- **MinIO**: Almacenamiento de objetos distribuido (3 nodos × 2 drives)
- **PostgreSQL + Patroni + etcd**: Base de datos con alta disponibilidad y elección de líder automática
- **JWT**: Autenticación stateless
- **Tailscale**: Red overlay para la demo entre equipos

## Decisiones de arquitectura

### Arquitectura simétrica

Cada nodo corre: Nginx, FastAPI, Worker, Patroni+PostgreSQL, etcd, RabbitMQ, MinIO. No hay nodo "maestro" a nivel de infraestructura — la elección de líder la manejan Patroni y etcd internamente.

### MinIO distribuido

- **3 nodos × 2 drives = 6 drives totales**
- MinIO aplica erasure coding: 3 fragmentos de datos + 3 de paridad
- Tolera perder un nodo completo (2 drives) sin pérdida de datos
- Cada instancia se **fija a su nodo** con `placement constraints` en Swarm para que los datos no migren

### Nginx como punto de entrada unificado

```
Usuario → Nginx → /          → Angular (archivos estáticos compilados)
               → /api/...   → FastAPI (round-robin entre los 3 nodos)
```

Un solo puerto expuesto al usuario. No hay distinción visible entre frontend y backend.

### Swarm: stateful vs stateless

| Tipo | Servicios | Estrategia Swarm |
|------|-----------|-----------------|
| Stateful | MinIO, Patroni, etcd | `placement constraints` fijos por nodo |
| Stateless | FastAPI, Worker, Nginx | `mode: global` (una instancia por nodo) |

### Red

- **Pruebas**: IPs locales (LAN)
- **Demo**: Tailscale — `docker swarm init --advertise-addr <IP_TAILSCALE>` en el manager inicial; los otros nodos hacen join con la IP Tailscale correspondiente

## Despliegue

### Inicializar el Swarm (solo una vez, desde máquina 1)

```bash
docker swarm init --advertise-addr <IP_MAQUINA1>
# Guardar el token que imprime para unir los otros nodos
```

### Unir las otras máquinas

```bash
# En máquina 2 y 3
docker swarm join --token <TOKEN> <IP_MAQUINA1>:2377
```

### Etiquetar los nodos (necesario para los placement constraints)

```bash
docker node update --label-add name=maquina1 <NODE_ID_1>
docker node update --label-add name=maquina2 <NODE_ID_2>
docker node update --label-add name=maquina3 <NODE_ID_3>
```

### Desplegar el stack

```bash
docker stack deploy -c stack.yml pda
```

### Verificar estado

```bash
docker stack services pda
docker service ps pda_minio1
```

## Requisitos

Ver `requirements.txt` para las dependencias de Python necesarias.
