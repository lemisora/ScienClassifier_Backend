#!/usr/bin/env bash
# Script para preparar al servidor remoto de la VPS (con Alma Linux o Fedora)

# Instalar dependencias para el sistema distribuido

# Dependencias a usar:
# - btop (Para monitorear el sistema)
# - Docker desde los repos de DockerCE para poder desplegar contenedores
# - Nix (para gestionar paquetes extra (en caso de usar Devenv o Flakes con dependencias externas del proyecto))

# Función para mostrar mensajes con formato
function print_message() {
    echo -e "\n\033[1;34m$1\033[0m\n"
}

# Función para confirmar acciones
function confirm_action() {
    read -p "$1 (s/n): " choice
    case "$choice" in
        s|S ) return 0 ;;
        * ) return 1 ;;
    esac
}

# Inicio del script
print_message "Bienvenido al script de preparación del servidor remoto."
echo "Este script instalará las dependencias necesarias para el sistema distribuido."
echo "Por favor, asegúrate de tener permisos de superusuario antes de continuar."

# Confirmar inicio
if ! confirm_action "¿Deseas continuar con la instalación?"; then
    echo "Instalación cancelada. ¡Hasta luego!"
    exit 0
fi


# Habilitar repositorios EPEL
print_message "Habilitando repositorios EPEL..."
dnf install epel-release -y
if [ $? -eq 0 ]; then
    echo "Repositorios EPEL habilitados correctamente."
else
    echo "Error al habilitar los repositorios EPEL. Revisa los logs e inténtalo de nuevo."
    exit 1
fi

# Añadir repositorios de DockerCE
print_message "Añadiendo repositorios de DockerCE..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
if [ $? -eq 0 ]; then
    echo "Repositorios de DockerCE añadidos correctamente."
else
    echo "Error al añadir los repositorios de DockerCE. Revisa los logs e inténtalo de nuevo."
    exit 1
fi

# Eliminar Podman y Buildah (si están instalados)
print_message "Eliminando Podman y Buildah (si están instalados)..."
dnf remove podman buildah -y
if [ $? -eq 0 ]; then
    echo "Podman y Buildah eliminados correctamente."
else
    echo "Error al eliminar Podman y Buildah. Revisa los logs e inténtalo de nuevo."
    exit 1
fi

# Instalar dependencias
print_message "Instalando dependencias necesarias..."
dnf install btop \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    git \
    -y
if [ $? -eq 0 ]; then
    echo "Dependencias instaladas correctamente."
else
    echo "Error al instalar las dependencias. Revisa los logs e inténtalo de nuevo."
    exit 1
fi

# Configuración del firewall
print_message "Configurando el firewall para Docker Swarm y servicios..."

# ==========================================
# Puertos de Docker Swarm
# ==========================================
sudo firewall-cmd --permanent --add-port=2377/tcp   # Swarm management
sudo firewall-cmd --permanent --add-port=7946/tcp   # Gossip entre nodos
sudo firewall-cmd --permanent --add-port=7946/udp
sudo firewall-cmd --permanent --add-port=4789/udp   # Overlay network (VXLAN)

# ==========================================
# Puertos de los servicios
# ==========================================
sudo firewall-cmd --permanent --add-port=2379/tcp   # etcd client
sudo firewall-cmd --permanent --add-port=2380/tcp   # etcd peer
sudo firewall-cmd --permanent --add-port=5432/tcp   # PostgreSQL
sudo firewall-cmd --permanent --add-port=8008/tcp   # Patroni API
sudo firewall-cmd --permanent --add-port=9000/tcp   # MinIO API
sudo firewall-cmd --permanent --add-port=9001/tcp   # MinIO consola nodo 1
sudo firewall-cmd --permanent --add-port=9002/tcp   # MinIO consola nodo 2
sudo firewall-cmd --permanent --add-port=5672/tcp   # RabbitMQ
sudo firewall-cmd --permanent --add-port=15672/tcp  # RabbitMQ management
sudo firewall-cmd --permanent --add-port=80/tcp     # nginx

# ==========================================
# Permitir tráfico interno de Docker
# ==========================================
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker_gwbridge
sudo firewall-cmd --permanent --zone=trusted --add-source=10.0.0.0/8

# ==========================================
# Aplicar todos los cambios
# ==========================================
sudo firewall-cmd --reload

# ==========================================
# Verificar que quedó correcto
# ==========================================
sudo firewall-cmd --list-all

# Finalización
print_message "¡Instalación y configuración completadas con éxito!"
echo "Ahora puedes usar las herramientas instaladas para configurar tu sistema distribuido."
echo "Recuerda iniciar el servicio de Docker con el siguiente comando:"
echo "  sudo systemctl start docker"
echo "Y habilitarlo para que se inicie automáticamente al arrancar el sistema:"
echo "  sudo systemctl enable docker"
