set dotenv-load
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

# Muestra los comandos disponibles
default:
    @just --list

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
        psql -h patroni -U ${PGUSER_SUPERUSER} -d postgres

# Crear bucket de MinIO manualmente (si no se creó automáticamente)
minio-create-bucket:
    docker run --rm --network scienclassifier_red_distribuida \
        minio/mc alias set local http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} && \
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
