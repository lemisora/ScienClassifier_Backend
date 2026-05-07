# ScienClassifier — Guía de Despliegue

Stack distribuido sobre Docker Swarm + Tailscale con autodescubrimiento automático de nodos.

## Arquitectura

```
3 VMs (Debian/Ubuntu)  ──Tailscale──►  Docker Swarm (3 managers)
                                         ├── etcd1/2/3       (quorum Raft)
                                         ├── patroni1/2/3    (PostgreSQL HA)
                                         ├── minio1/2/3      (object storage)
                                         ├── rabbitmq1/2/3   (message queue)
                                         ├── fastapi          (mode: global)
                                         ├── worker           (mode: global)
                                         └── nginx            (mode: global)
```

El nodo con la **IP Tailscale más baja** actúa como manager automáticamente.

> **Repositorios separados:**
> - Código fuente → GitHub: `github.com/lemisora/ScienClassifier_Backend`
> - Imágenes Docker → Docker Hub: `docker.io/pdanodos/{fastapi,worker,nginx}`

---

## Requisitos previos por VM

- Debian 12+ o Ubuntu 22.04+
- Docker Engine instalado (`curl -fsSL https://get.docker.com | bash`)
- Tailscale instalado y conectado (`tailscale up --authkey=<key>`)
- Usuario en el grupo `docker` (`sudo usermod -aG docker $USER && newgrp docker`)

---

## Paso 1 — Construir y publicar imágenes (máquina de desarrollo)

```bash
cd ScienClassifier_Backend

# Asegurarse de estar en la rama que quieres desplegar
git checkout feature/monitor   # o la rama que corresponda

# Login a Docker Hub (cuenta pdanodos)
docker login -u pdanodos

# Compilar Angular + construir las 3 imágenes Docker
just build

# Subir a docker.io/pdanodos/
just push
```

> `just build` compila el frontend Angular primero y lo empaqueta dentro de la
> imagen nginx automáticamente. Si solo cambiaste el backend: `just build-no-ng && just push`

---

## Paso 2 — Bootstrap en cada VM

Ejecutar en las **3 VMs en paralelo** (3 terminales SSH simultáneas).

```bash
# Con token de Docker Hub (si las imágenes son privadas)
export DOCKER_HUB_TOKEN="dckr_pat_xxxx"
curl -fsSL https://raw.githubusercontent.com/lemisora/ScienClassifier_Backend/testing_VMs_tailscale/deploy/bootstrap.sh | bash

# Sin token (imágenes públicas)
curl -fsSL https://raw.githubusercontent.com/lemisora/ScienClassifier_Backend/testing_VMs_tailscale/deploy/bootstrap.sh | bash
```

El bootstrap hace automáticamente:
1. Mueve Docker data-root a `/srv` (evita llenar `/var`)
2. Login a Docker Hub si `DOCKER_HUB_TOKEN` está exportado
3. Instala `jq`, `git`, `curl`, `just`
4. Clona el repo en `/opt/scienclassifier` (rama `testing_VMs_tailscale`)
5. Abre puertos en UFW o nftables según lo disponible
6. Arranca el servicio `pda-agent` (systemd)

### Ver progreso en tiempo real

```bash
sudo journalctl -fu pda-agent
```

El agente hace el resto automáticamente:
- Espera a que los 3 nodos estén en Tailscale
- Elige el manager (IP Tailscale más baja)
- Inicializa el Swarm y une los nodos
- Etiqueta los nodos (`etcd=true`, `minio=true`)
- Despliega el stack
- Inicializa la base de datos y crea el usuario admin

El cluster está listo cuando el log del manager dice:
```
Stack desplegado. Cluster con 3 nodos activo.
```

---

## Paso 3 — Verificar el cluster

Desde cualquier nodo:

```bash
cd /opt/scienclassifier
just status
```

Estado esperado — todos los servicios deben mostrar `N/N`:

| Servicio | Réplicas |
|---|---|
| etcd1/2/3 | 1/1 |
| patroni1/2/3 | 1/1 |
| minio1/2/3 | 1/1 |
| rabbitmq1/2/3 | 1/1 |
| fastapi | 3/3 |
| worker | 3/3 |
| nginx | 3/3 |

---

## Paso 4 — Acceder a la aplicación

El frontend está disponible en cualquier nodo del cluster:

```
http://<ip-de-cualquier-vm>/
```

### Credenciales del admin por defecto

| Campo | Valor |
|---|---|
| Usuario | `admin` |
| Contraseña | `admin1234` |

El usuario admin se crea **automáticamente** al arrancar FastAPI si no existe ningún admin.
Para cambiar las credenciales, editar en `.env.example` antes del deploy:

```
ADMIN_USERNAME=mi_admin
ADMIN_PASSWORD=mi_password_segura
```

### Monitor del cluster (feature/monitor)

Acceder con el usuario admin en:
```
http://<ip>/admin/monitor
```

Muestra en tiempo real:
- Estado de los nodos Patroni (primary / replicas)
- Cola RabbitMQ (`pdf_processing`)
- Estadísticas de la base de datos

---

## Comandos útiles

```bash
cd /opt/scienclassifier

just status           # Estado del cluster y servicios
just logs fastapi     # Logs en tiempo real (también: patroni, nginx, worker...)
just patroni-status   # Estado de Patroni via REST API
just agent-status     # Estado del pda-agent
just update           # Forzar actualización de todos los servicios
just deploy           # Redesplegar el stack
just down             # Bajar el stack (sin borrar volúmenes)
just db-init          # Inicializar la base de datos manualmente
just psql             # Conectarse a PostgreSQL
```

---

## Troubleshooting

### Servicio con 0/N réplicas

```bash
docker service ps scienclassifier_<servicio> --no-trunc
```

| Error | Causa | Fix |
|---|---|---|
| `no space left on device` | `/var` lleno | El bootstrap lo resuelve. Fix manual abajo. |
| `No such image` | Imagen no subida o sin credenciales | `docker login -u pdanodos` en el manager y `just deploy` |
| Crash de la app | Error en el código | `just logs <servicio>` |

### /var lleno en una VM (fix manual)

```bash
sudo systemctl stop docker.socket docker.service
sudo mv /var/lib/docker /srv/docker
echo '{"data-root": "/srv/docker"}' | sudo tee /etc/docker/daemon.json
sudo systemctl start docker
```

### Puerto 9999 bloqueado (worker se queda en "Polling...")

```bash
# Si hay nftables activo
sudo nft add rule inet filter input tcp dport 9999 accept
```

### Patroni no elige primary

```bash
just patroni-status
just logs patroni
```

Si etcd está en quorum (1/1 en los 3 nodos), Patroni debería elegir primary en ~30s.

---

## Reset completo del cluster

```bash
# En el manager
cd /opt/scienclassifier
just down
docker swarm leave --force

# En los workers
docker swarm leave --force

# Borrar volúmenes (opcional — borra todos los datos)
docker volume prune -f

# Volver a desplegar desde cero
sudo systemctl restart pda-agent
```
