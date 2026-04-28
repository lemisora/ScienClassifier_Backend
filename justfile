set dotenv-load
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

# Muestra los comandos disponibles
default:
    @just --list

# ==========================================
# Setup del nodo (Debian/Ubuntu)
# ==========================================

# Instala todas las dependencias y deja el nodo listo para unirse al Swarm
# Ejecutar como usuario normal con sudo disponible (no como root)
setup:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=== ScienClassifier — Setup del nodo ==="
    echo ""

    # Verificar que no sea root
    if [ "$EUID" -eq 0 ]; then
        echo "ERROR: No ejecutes esto como root. Usa un usuario normal con sudo."
        exit 1
    fi

    # Verificar Debian/Ubuntu
    if ! command -v apt-get &>/dev/null; then
        echo "ERROR: Este script requiere Debian o Ubuntu (apt-get no encontrado)."
        exit 1
    fi

    echo ">>> [1/5] Actualizando paquetes..."
    sudo apt-get update -qq

    echo ">>> [2/5] Instalando dependencias base..."
    sudo apt-get install -y -qq \
        curl ca-certificates gnupg lsb-release \
        git make

    echo ">>> [3/5] Instalando Docker Engine..."
    if command -v docker &>/dev/null; then
        echo "    Docker ya instalado: $(docker --version)"
    else
        # Repositorio oficial de Docker
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg \
            | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/debian \
          $(lsb_release -cs) stable" \
          | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update -qq
        sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin
        sudo systemctl enable --now docker
        echo "    Docker instalado: $(docker --version)"
    fi

    # Agregar usuario al grupo docker (evita sudo en cada comando)
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        echo "    Usuario '$USER' agregado al grupo docker."
        echo "    IMPORTANTE: cierra sesion y vuelve a entrar para que tome efecto,"
        echo "    o ejecuta: newgrp docker"
    fi

    echo ">>> [4/5] Instalando just..."
    if command -v just &>/dev/null; then
        echo "    just ya instalado: $(just --version)"
    else
        # Instala just via el instalador oficial
        curl -fsSL https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
        echo "    just instalado: $(just --version)"
    fi

    echo ">>> [5/5] Abriendo puertos de Docker Swarm en UFW (si está activo)..."
    if command -v ufw &>/dev/null && sudo ufw status | grep -q "Status: active"; then
        sudo ufw allow 2377/tcp comment "Docker Swarm manager"
        sudo ufw allow 7946/tcp comment "Docker Swarm gossip"
        sudo ufw allow 7946/udp comment "Docker Swarm gossip"
        sudo ufw allow 4789/udp comment "Docker Swarm overlay"
        sudo ufw allow 80/tcp   comment "Nginx HTTP"
        echo "    Puertos abiertos en UFW."
    else
        echo "    UFW no activo — omitiendo reglas de firewall."
    fi

    echo ""
    echo "=== Setup completado ==="
    echo ""
    echo "Pasos siguientes:"
    echo "  Si eres el MANAGER (primer nodo):"
    echo "    1. Edita .env con tus valores"
    echo "    2. just init-swarm"
    echo "    3. just label-node $(hostname)"
    echo "    4. just build && just push && just deploy"
    echo ""
    echo "  Si eres un WORKER (te unes al swarm existente):"
    echo "    1. Obtén el token del manager (.env -> SWARM_WORKER_TOKEN)"
    echo "    2. just join-swarm"
    echo "    3. Pídele al manager: docker node promote $(hostname)"
    echo "    4. Pídele al manager: just label-node $(hostname)"

# ==========================================
# Tailscale
# ==========================================

# Abre los puertos de Swarm sobre la interfaz Tailscale (ejecutar en cada nodo)
tailscale-firewall:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v firewall-cmd &>/dev/null; then
        echo ">>> Configurando firewalld para Tailscale..."
        sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0
        sudo firewall-cmd --permanent --add-port=2377/tcp
        sudo firewall-cmd --permanent --add-port=7946/tcp
        sudo firewall-cmd --permanent --add-port=7946/udp
        sudo firewall-cmd --permanent --add-port=4789/udp
        sudo firewall-cmd --reload
        echo "OK — firewalld actualizado."
    elif command -v ufw &>/dev/null; then
        echo ">>> Configurando UFW para Tailscale..."
        sudo ufw allow in on tailscale0
        sudo ufw allow 2377/tcp
        sudo ufw allow 7946/tcp
        sudo ufw allow 7946/udp
        sudo ufw allow 4789/udp
        sudo ufw reload
        echo "OK — UFW actualizado."
    else
        echo "No se detectó firewall activo — omitiendo."
    fi

# Muestra las IPs Tailscale de este nodo
tailscale-ip:
    @tailscale ip -4 2>/dev/null || echo "Tailscale no está corriendo"

# Migra el Swarm de LAN a Tailscale.
# ATENCION: baja el stack, abandona el Swarm y lo re-inicializa.
# Ejecutar SOLO en el manager. Luego hacer join-swarm en los otros nodos.
migrate-to-tailscale:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Migrando Swarm a Tailscale ==="
    echo "MANAGER_IP configurada: ${MANAGER_IP}"
    echo ""

    # Verificar que MANAGER_IP sea una IP Tailscale (100.x.x.x)
    if [[ ! "${MANAGER_IP}" =~ ^100\. ]]; then
        echo "ERROR: MANAGER_IP (${MANAGER_IP}) no parece una IP Tailscale (100.x.x.x)"
        echo "Actualiza MANAGER_IP en .env con tu IP de Tailscale (just tailscale-ip)"
        exit 1
    fi

    echo ">>> [1/4] Bajando el stack..."
    docker stack rm scienclassifier 2>/dev/null || true
    sleep 5

    echo ">>> [2/4] Abandonando el Swarm actual..."
    docker swarm leave --force 2>/dev/null || true
    sleep 3

    echo ">>> [3/4] Inicializando nuevo Swarm sobre Tailscale (${MANAGER_IP})..."
    docker swarm init --advertise-addr ${MANAGER_IP}

    echo ">>> [4/4] Guardando tokens en .env..."
    # Eliminar tokens viejos y guardar los nuevos
    sed -i '/^SWARM_WORKER_TOKEN=/d' .env
    sed -i '/^SWARM_MANAGER_TOKEN=/d' .env
    echo "SWARM_WORKER_TOKEN=$(docker swarm join-token worker -q)"  >> .env
    echo "SWARM_MANAGER_TOKEN=$(docker swarm join-token manager -q)" >> .env

    echo ""
    echo "=== Swarm inicializado sobre Tailscale ==="
    echo ""
    echo "Ahora en cada nodo worker ejecuta:"
    echo "  just tailscale-firewall"
    echo "  just join-swarm"
    echo ""
    echo "Luego en este manager:"
    echo "  docker node promote devhome-1"
    echo "  docker node promote kali"
    echo "  just label-node devaxpc"
    echo "  just label-node devhome-1"
    echo "  just label-node kali"
    echo "  just deploy"

# ==========================================
# Inicialización del Swarm
# ==========================================

# Inicializa el swarm en este nodo (ejecutar solo en el manager principal)
init-swarm:
    docker swarm init --advertise-addr ${MANAGER_IP}
    @echo "Guardando tokens en .env..."
    @echo "" >> .env
    @echo "SWARM_WORKER_TOKEN=$(docker swarm join-token worker -q)" >> .env
    @echo "SWARM_MANAGER_TOKEN=$(docker swarm join-token manager -q)" >> .env
    @echo "Tokens guardados. Comparte el .env con tu equipo por canal seguro."

# Une este nodo al swarm como worker
join-swarm:
    docker swarm join --token ${SWARM_WORKER_TOKEN} ${MANAGER_IP}:2377

# Une este nodo al swarm como manager (recomendado para tolerancia a fallos)
join-swarm-manager:
    docker swarm join --token ${SWARM_MANAGER_TOKEN} ${MANAGER_IP}:2377

# Rota los tokens del swarm (usar si se filtraron)
rotate-tokens:
    docker swarm join-token --rotate worker
    docker swarm join-token --rotate manager

# ==========================================
# Etiquetas de nodos
# ==========================================

# Etiqueta un nodo para correr etcd y MinIO: just label-node nixos-desktop
label-node node:
    docker node update --label-add etcd=true {{node}}
    docker node update --label-add minio=true {{node}}

# Quita las etiquetas de un nodo
unlabel-node node:
    docker node update --label-rm etcd {{node}}
    docker node update --label-rm minio {{node}}

# Muestra las etiquetas de todos los nodos
list-labels:
    docker node ls -q | xargs -I{} docker node inspect {} --format '{{{{.Description.Hostname}}}}: {{{{.Spec.Labels}}}}'

# ==========================================
# Build de imágenes
# ==========================================

# Compila el frontend Angular y copia el dist a nginx/html/
ng-build:
    cd ../ScienClassifier_Frontend/scienclassifier && npm install && npx ng build --configuration=production
    rm -rf nginx/html
    cp -r ../ScienClassifier_Frontend/scienclassifier/dist/scienclassifier/browser nginx/html

# Construye las 3 imágenes (incluye compilar Angular)
build: ng-build
    docker build -f Dockerfile.fastapi -t ${REGISTRY:-localhost}/fastapi:latest .
    docker build -f Dockerfile.worker  -t ${REGISTRY:-localhost}/worker:latest  .
    docker build -f Dockerfile.nginx   -t ${REGISTRY:-localhost}/nginx:latest   .

# Solo construye sin compilar Angular (cuando el dist ya está actualizado)
build-no-ng:
    docker build -f Dockerfile.fastapi -t ${REGISTRY:-localhost}/fastapi:latest .
    docker build -f Dockerfile.worker  -t ${REGISTRY:-localhost}/worker:latest  .
    docker build -f Dockerfile.nginx   -t ${REGISTRY:-localhost}/nginx:latest   .

# Solo construye sin empujar (útil para pruebas locales)
build-local: ng-build
    docker build -f Dockerfile.fastapi -t fastapi:latest .
    docker build -f Dockerfile.worker  -t worker:latest  .
    docker build -f Dockerfile.nginx   -t nginx:latest   .

# Empuja las imágenes al registro configurado en .env
push:
    docker push ${REGISTRY:-localhost}/fastapi:latest
    docker push ${REGISTRY:-localhost}/worker:latest
    docker push ${REGISTRY:-localhost}/nginx:latest

# ==========================================
# Despliegue
# ==========================================

# Despliega o actualiza el stack completo
deploy:
    docker stack deploy -c docker-stack.yml scienclassifier --with-registry-auth

# Baja el stack sin borrar volúmenes
down:
    docker stack rm scienclassifier

# Fuerza la actualización de todos los servicios
update:
    docker service update --force scienclassifier_etcd1
    docker service update --force scienclassifier_etcd2
    docker service update --force scienclassifier_etcd3
    docker service update --force scienclassifier_patroni1
    docker service update --force scienclassifier_patroni2
    docker service update --force scienclassifier_patroni3
    docker service update --force scienclassifier_minio1
    docker service update --force scienclassifier_minio2
    docker service update --force scienclassifier_minio3
    docker service update --force scienclassifier_rabbitmq1
    docker service update --force scienclassifier_rabbitmq2
    docker service update --force scienclassifier_rabbitmq3
    docker service update --force scienclassifier_fastapi
    docker service update --force scienclassifier_worker
    docker service update --force scienclassifier_nginx

# ==========================================
# Monitoreo
# ==========================================

# Estado general del cluster y servicios
status:
    @echo "=== Nodos del cluster ==="
    docker node ls
    @echo ""
    @echo "=== Servicios del stack ==="
    docker stack services scienclassifier
    @echo ""
    @echo "=== Tareas con errores ==="
    docker stack ps scienclassifier --filter desired-state=running --no-trunc

# Sigue los logs de un servicio: just logs fastapi
logs service="patroni":
    docker service logs scienclassifier_{{service}} --follow --tail 50

# Ver estado de Patroni via REST API
patroni-status:
    curl -s http://${MANAGER_IP}:8008/cluster | python3 -m json.tool

# Verificar cuál instancia de Patroni es el primary e inicializar el usuario admin
# Uso: just db-init
db-init:
    python3 scripts/db_init.py
# Verificar health del cluster MinIO
minio-health:
    curl -sf http://${MANAGER_IP}:9000/minio/health/cluster && echo "MinIO cluster OK" || echo "MinIO cluster FAIL"

# Ver estado de RabbitMQ
rabbitmq-status:
    docker run --rm --network scienclassifier_red_distribuida \
        curlimages/curl curl -s -u ${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS} \
        http://rabbitmq1:15672/api/nodes | python3 -m json.tool

# ==========================================
# Utilidades
# ==========================================

# Conectarse a PostgreSQL
psql:
    docker run --rm -it --network scienclassifier_red_distribuida \
        postgres:17-alpine \
        psql -h patroni1 -U ${PGUSER_SUPERUSER} -d postgres

# Crear bucket de MinIO manualmente (si no se creó automáticamente)
minio-create-bucket:
    docker run --rm --network scienclassifier_red_distribuida \
        minio/mc alias set local http://minio1:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} && \
        docker run --rm --network scienclassifier_red_distribuida \
        minio/mc mb local/${MINIO_BUCKET} --ignore-existing

# Prueba local del cluster MinIO sin Swarm (3 nodos en una sola máquina)
test-minio:
    docker compose -f tests/docker-compose.minio-test.yml up -d
    @echo "Esperando que el cluster forme quorum..."
    until curl -sf http://localhost:9000/minio/health/cluster; do sleep 3; done
    @echo "MinIO cluster OK — consola: http://localhost:9001"

# Baja el cluster de prueba de MinIO
test-minio-down:
    docker compose -f tests/docker-compose.minio-test.yml down -v

# Verifica que Docker y el Swarm estén listos antes de hacer deploy
check:
    docker info
    docker node ls

# ==========================================
# PDA Node Agent (autodescubrimiento)
# ==========================================

# Estado actual del cluster (requiere que el agente esté corriendo)
agent-status:
    @curl -s http://localhost:9999/state.json | python3 -m json.tool 2>/dev/null \
        || echo "El agente no está sirviendo estado (¿está corriendo? sudo systemctl status pda-agent)"

# Logs del agente en tiempo real
agent-logs:
    sudo journalctl -fu pda-agent

# Reiniciar el agente manualmente
agent-restart:
    sudo systemctl restart pda-agent

# Ver nodos pendientes de ser admitidos
agent-pending:
    @curl -s http://localhost:9999/state.json \
        | python3 -c "import sys,json; s=json.load(sys.stdin); p=s.get('pending_nodes',[]); \
          print('Pendientes:', p if p else 'ninguno'); \
          print('Activos:   ', s.get('active_nodes',[]))"
