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

# Marca un nodo para correr etcd: just label-etcd nixos-desktop
label-etcd node:
    docker node update --label-add etcd=true {{node}}

# Quita la etiqueta etcd de un nodo: just unlabel-etcd nixos-desktop
unlabel-etcd node:
    docker node update --label-rm etcd {{node}}

# Muestra las etiquetas de todos los nodos
list-labels:
    docker node ls -q | xargs -I{} docker node inspect {} --format '{{{{.Description.Hostname}}}}: {{{{.Spec.Labels}}}}'

# ==========================================
# Despliegue
# ==========================================

# Despliega o actualiza el stack completo
deploy:
    docker stack deploy -c docker-stack.yml scienclassifier --with-registry-auth

# Baja el stack sin borrar volúmenes
down:
    docker stack rm scienclassifier

# Fuerza la actualización de todos los servicios (pull de imágenes nuevas)
update:
    docker service update --force scienclassifier_etcd
    docker service update --force scienclassifier_patroni
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
    docker stack ps scienclassifier --no-trunc

# Sigue los logs de un servicio (default: patroni)
logs service="patroni":
    docker service logs scienclassifier_{{service}} --follow --tail 50

# Ver estado de Patroni via REST API
patroni-status:
    curl -s http://${MANAGER_IP}:8008/cluster | python3 -m json.tool

# ==========================================
# Utilidades
# ==========================================

# Conectarse a PostgreSQL en el nodo manager
psql:
    docker run --rm -it --network scienclassifier_red_distribuida \
        postgres:17-alpine \
        psql -h patroni -U ${PGUSER_SUPERUSER} -d postgres

# Verifica que el stack esté corriendo antes de hacer deploy
check:
    docker info
    docker node ls
