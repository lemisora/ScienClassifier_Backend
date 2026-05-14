#!/usr/bin/env bash
# ============================================================
# ScienClassifier — Bootstrap de nodo
# ============================================================
# Prerrequisitos (hacer a mano antes de correr esto):
#   1. Instalar Docker
#   2. Instalar Tailscale y conectarlo:  tailscale up --authkey=...
#
# Uso:
#   bash /ruta/a/bootstrap.sh
#   o clonar el repo primero y correr desde ahí.
#
# Lo que hace este script:
#   - Mueve Docker data-root a /srv (evita llenar /var en VMs pequeñas)
#   - Login a Docker Hub si DOCKER_HUB_TOKEN está exportado
#   - Instala jq, git, curl, just
#   - Clona / actualiza el repo en /opt/scienclassifier
#   - Abre los puertos necesarios (UFW o nftables según lo disponible)
#   - Instala y arranca el servicio pda-agent (systemd)
#
# El agente detecta automáticamente los otros nodos y forma
# el cluster. Ver logs con:  sudo journalctl -fu pda-agent
# ============================================================

set -euo pipefail

# ── Configuración ─────────────────────────────────────────
REGISTRY="pdanodos"
BRANCH="recover-fix"
REPO_URL="https://github.com/lemisora/ScienClassifier_Backend.git"
INSTALL_DIR="/opt/scienclassifier"
DOCKER_DATA_ROOT="/srv/docker"
# ─────────────────────────────────────────────────────────

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2; exit 1; }

detect_pkg_manager() {
    local os_id os_like
    os_id=""
    os_like=""

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-}"
        os_like="${ID_LIKE:-}"
    fi

    if [[ "$os_id" =~ ^(debian|ubuntu)$ ]] || [[ "$os_like" == *"debian"* ]]; then
        echo "apt"
        return
    fi

    if [[ "$os_id" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$os_like" == *"rhel"* ]] || [[ "$os_like" == *"fedora"* ]]; then
        if command -v dnf &>/dev/null; then
            echo "dnf"
            return
        fi
    fi

    die "Distribución no soportada para instalación automática de dependencias (ID='$os_id', ID_LIKE='$os_like')."
}

install_deps() {
    local pkg_mgr="$1"
    case "$pkg_mgr" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y -qq jq git curl ca-certificates
            ;;
        dnf)
            sudo dnf makecache -q
            sudo dnf install -y -q jq git curl ca-certificates
            ;;
        *)
            die "Gestor de paquetes no soportado: $pkg_mgr"
            ;;
    esac
}

echo ""
echo "┌──────────────────────────────────────────────┐"
echo "│   ScienClassifier — Bootstrap de nodo        │"
echo "└──────────────────────────────────────────────┘"
echo ""

# ── Verificar prerequisitos ───────────────────────────────
command -v docker    &>/dev/null || die "Docker no instalado."
command -v tailscale &>/dev/null || die "Tailscale no instalado."
docker info &>/dev/null          || die "Docker no está corriendo (¿falta 'sudo usermod -aG docker \$USER'?)."
tailscale status &>/dev/null     || die "Tailscale no está conectado. Correr: tailscale up --authkey=..."

# ── Configurar Docker data-root en /srv ───────────────────
# /var suele ser una partición pequeña en VMs; /srv tiene más espacio.
configure_docker_dataroot() {
    local cfg=/etc/docker/daemon.json

    if [[ -f "$cfg" ]] && grep -q '"data-root"' "$cfg" 2>/dev/null; then
        log "Docker data-root ya configurado ($(jq -r '."data-root"' "$cfg"))."
        return
    fi

    log "Configurando Docker data-root → $DOCKER_DATA_ROOT..."
    sudo mkdir -p "$DOCKER_DATA_ROOT"
    echo "{\"data-root\": \"$DOCKER_DATA_ROOT\"}" | sudo tee "$cfg" > /dev/null

    if [[ -d /var/lib/docker ]] && sudo ls /var/lib/docker &>/dev/null; then
        log "Moviendo datos Docker existentes a $DOCKER_DATA_ROOT..."
        sudo systemctl stop docker.socket docker.service 2>/dev/null || true
        sudo rsync -a /var/lib/docker/ "$DOCKER_DATA_ROOT/" 2>/dev/null \
            || sudo cp -a /var/lib/docker/. "$DOCKER_DATA_ROOT/"
        sudo systemctl start docker
    else
        sudo systemctl restart docker
    fi
    log "Docker reiniciado con data-root $DOCKER_DATA_ROOT."
}
configure_docker_dataroot

# ── Login a Docker Hub (opcional) ─────────────────────────
# Exporta DOCKER_HUB_TOKEN antes de correr el bootstrap para
# que el manager tenga credenciales al hacer --with-registry-auth.
# Ejemplo: export DOCKER_HUB_TOKEN="dckr_pat_xxx"
if [[ -n "${DOCKER_HUB_TOKEN:-}" ]]; then
    log "Iniciando sesión en Docker Hub ($REGISTRY)..."
    echo "$DOCKER_HUB_TOKEN" | docker login -u "$REGISTRY" --password-stdin \
        && log "Docker Hub login exitoso." \
        || log "WARN: Docker Hub login falló — las imágenes deben ser públicas."
else
    log "DOCKER_HUB_TOKEN no definido. Si las imágenes son privadas: docker login -u $REGISTRY"
fi

# ── [1/5] Instalar dependencias ──────────────────────────
log "[1/5] Actualizando paquetes e instalando dependencias..."
PKG_MANAGER="$(detect_pkg_manager)"
log "       Gestor detectado: $PKG_MANAGER"
install_deps "$PKG_MANAGER"

log "[2/5] Instalando just..."
if ! command -v just &>/dev/null; then
    curl -fsSL https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
else
    log "       just ya instalado: $(just --version)"
fi

# ── [3/5] Clonar o actualizar repo ───────────────────────
log "[3/5] Preparando repositorio en $INSTALL_DIR..."
if [[ -d "$INSTALL_DIR/.git" ]]; then
    sudo git -C "$INSTALL_DIR" fetch origin
    sudo git -C "$INSTALL_DIR" checkout "$BRANCH"
    sudo git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
    log "       Repo actualizado (rama $BRANCH)."
else
    sudo git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    log "       Repo clonado (rama $BRANCH)."
fi
sudo chown -R "$(id -u):$(id -g)" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/deploy/node-agent.sh"

# ── [4/5] Guardar configuración del agente ───────────────
log "[4/5] Guardando configuración del agente..."
sudo mkdir -p /var/lib/pda-cluster
echo "PDA_REGISTRY=$REGISTRY" | sudo tee /var/lib/pda-cluster/config.env > /dev/null

# ── [4/5] Abrir puertos (UFW o nftables) ─────────────────
configure_firewall() {
    local tcp_ports=(2377 7946 9999 80 8008 9001)
    local udp_ports=(7946 4789)

    if command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        log "       Configurando UFW..."
        sudo ufw allow in on tailscale0 comment "Tailscale" 2>/dev/null || true
        for p in "${tcp_ports[@]}"; do sudo ufw allow "$p/tcp" comment "ScienClassifier" 2>/dev/null || true; done
        for p in "${udp_ports[@]}"; do sudo ufw allow "$p/udp" comment "ScienClassifier" 2>/dev/null || true; done
        sudo ufw reload
        log "       UFW configurado."
    elif command -v nft &>/dev/null && sudo nft list ruleset 2>/dev/null | grep -q "filter"; then
        log "       Configurando nftables..."
        for p in "${tcp_ports[@]}"; do
            sudo nft add rule inet filter input tcp dport "$p" accept 2>/dev/null || true
        done
        for p in "${udp_ports[@]}"; do
            sudo nft add rule inet filter input udp dport "$p" accept 2>/dev/null || true
        done
        log "       nftables configurado."
    else
        log "       Sin firewall activo — omitiendo reglas."
    fi
}
configure_firewall

# ── [5/5] Instalar y arrancar servicio systemd ───────────
log "[5/5] Instalando servicio pda-agent..."
sudo cp "$INSTALL_DIR/deploy/pda-agent.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable pda-agent
sudo systemctl restart pda-agent

echo ""
echo "┌──────────────────────────────────────────────┐"
echo "│   Bootstrap completado                        │"
echo "└──────────────────────────────────────────────┘"
echo ""
echo "El agente está corriendo. Ver progreso en tiempo real:"
echo "  sudo journalctl -fu pda-agent"
echo ""
echo "Estado del cluster (cuando esté listo):"
echo "  curl -s http://localhost:9999/state.json | jq ."
echo ""
echo "El cluster arranca solo cuando hay 3 nodos en Tailscale."
echo ""
echo "Si las imágenes de Docker Hub son privadas, exporta el token ANTES"
echo "de correr el bootstrap en el nodo manager (IP Tailscale más baja):"
echo "  export DOCKER_HUB_TOKEN=\"dckr_pat_xxxx\""
echo "  bash bootstrap.sh"
echo ""
echo "O haz login manual antes de que el agente despliegue:"
echo "  docker login -u $REGISTRY"
