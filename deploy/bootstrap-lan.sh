#!/usr/bin/env bash
# ============================================================
# ScienClassifier — Bootstrap de nodo (LAN, sin Tailscale)
# ============================================================
# Prerequisitos (hacer a mano antes de correr esto):
#   1. Instalar Docker
#   2. Los 3 nodos conectados en la misma red LAN
#
# Uso (en cada nodo):
#   bash bootstrap-lan.sh
#
# Lo que hace este script:
#   - Mueve Docker data-root a /srv (evita llenar /var)
#   - Login a Docker Hub si DOCKER_HUB_TOKEN está exportado
#   - Instala jq, git, curl, just
#   - Clona / actualiza el repo en /opt/scienclassifier
#   - Abre los puertos necesarios en el firewall
#   - Instala y arranca el servicio pda-agent-lan (systemd)
#
# El agente detecta automáticamente los otros nodos por escaneo
# de subred y forma el cluster. Ver logs con:
#   sudo journalctl -fu pda-agent-lan
# ============================================================

set -euo pipefail

REGISTRY="pdanodos"
BRANCH="testing_VMs_tailscale"
REPO_URL="https://github.com/lemisora/ScienClassifier_Backend.git"
INSTALL_DIR="/opt/scienclassifier"
DOCKER_DATA_ROOT="/srv/docker"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2; exit 1; }

detect_pkg_manager() {
    local os_id os_like
    os_id=""; os_like=""
    [[ -r /etc/os-release ]] && source /etc/os-release && os_id="${ID:-}" && os_like="${ID_LIKE:-}"

    if [[ "$os_id" =~ ^(debian|ubuntu)$ ]] || [[ "$os_like" == *"debian"* ]]; then
        echo "apt"; return
    fi
    if [[ "$os_id" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || \
       [[ "$os_like" == *"rhel"* ]] || [[ "$os_like" == *"fedora"* ]]; then
        command -v dnf &>/dev/null && echo "dnf" && return
    fi
    die "Distribución no soportada (ID='${os_id:-?}')."
}

install_deps() {
    case "$1" in
        apt) sudo apt-get update -qq && sudo apt-get install -y -qq jq git curl ca-certificates ;;
        dnf) sudo dnf makecache -q   && sudo dnf install -y -q  jq git curl ca-certificates ;;
        *)   die "Gestor no soportado: $1" ;;
    esac
}

configure_firewall() {
    local tcp_ports=(2377 7946 9998 9999 80)
    local udp_ports=(7946 4789)

    if command -v firewall-cmd &>/dev/null && sudo firewall-cmd --state &>/dev/null 2>&1; then
        log "Configurando firewalld..."
        for p in "${tcp_ports[@]}"; do sudo firewall-cmd --permanent --add-port="${p}/tcp" 2>/dev/null || true; done
        for p in "${udp_ports[@]}"; do sudo firewall-cmd --permanent --add-port="${p}/udp" 2>/dev/null || true; done
        sudo firewall-cmd --reload
        log "firewalld configurado."
    elif command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        log "Configurando UFW..."
        for p in "${tcp_ports[@]}"; do sudo ufw allow "$p/tcp" comment "ScienClassifier" 2>/dev/null || true; done
        for p in "${udp_ports[@]}"; do sudo ufw allow "$p/udp" comment "ScienClassifier" 2>/dev/null || true; done
        sudo ufw reload
        log "UFW configurado."
    elif command -v nft &>/dev/null && sudo nft list ruleset 2>/dev/null | grep -q "filter"; then
        log "Configurando nftables..."
        for p in "${tcp_ports[@]}"; do sudo nft add rule inet filter input tcp dport "$p" accept 2>/dev/null || true; done
        for p in "${udp_ports[@]}"; do sudo nft add rule inet filter input udp dport "$p" accept 2>/dev/null || true; done
        log "nftables configurado."
    else
        log "Sin firewall activo — omitiendo reglas."
    fi
}

echo ""
echo "┌──────────────────────────────────────────────┐"
echo "│   ScienClassifier — Bootstrap LAN            │"
echo "└──────────────────────────────────────────────┘"
echo ""

command -v docker &>/dev/null || die "Docker no instalado."
docker info &>/dev/null       || die "Docker no está corriendo."

# ── Docker data-root ──────────────────────────────────────
configure_docker_dataroot() {
    local cfg=/etc/docker/daemon.json
    if [[ -f "$cfg" ]] && grep -q '"data-root"' "$cfg" 2>/dev/null; then
        log "Docker data-root ya configurado."; return
    fi
    log "Configurando Docker data-root → $DOCKER_DATA_ROOT..."
    sudo mkdir -p "$DOCKER_DATA_ROOT"
    echo "{\"data-root\": \"$DOCKER_DATA_ROOT\"}" | sudo tee "$cfg" > /dev/null
    if [[ -d /var/lib/docker ]] && sudo ls /var/lib/docker &>/dev/null; then
        sudo systemctl stop docker.socket docker.service 2>/dev/null || true
        sudo rsync -a /var/lib/docker/ "$DOCKER_DATA_ROOT/" 2>/dev/null \
            || sudo cp -a /var/lib/docker/. "$DOCKER_DATA_ROOT/"
        sudo systemctl start docker
    else
        sudo systemctl restart docker
    fi
}
configure_docker_dataroot

# ── Docker Hub login ──────────────────────────────────────
if [[ -n "${DOCKER_HUB_TOKEN:-}" ]]; then
    log "Iniciando sesión en Docker Hub ($REGISTRY)..."
    echo "$DOCKER_HUB_TOKEN" | docker login -u "$REGISTRY" --password-stdin \
        && log "Docker Hub login exitoso." \
        || log "WARN: Docker Hub login falló."
else
    log "DOCKER_HUB_TOKEN no definido. Si las imágenes son privadas: docker login -u $REGISTRY"
fi

log "[1/5] Instalando dependencias..."
PKG_MANAGER="$(detect_pkg_manager)"
log "       Gestor: $PKG_MANAGER"
install_deps "$PKG_MANAGER"

log "[2/5] Instalando just..."
if ! command -v just &>/dev/null; then
    curl -fsSL https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
else
    log "       just ya instalado: $(just --version)"
fi

log "[3/5] Preparando repositorio en $INSTALL_DIR..."
if [[ -d "$INSTALL_DIR/.git" ]]; then
    sudo git -C "$INSTALL_DIR" fetch origin
    sudo git -C "$INSTALL_DIR" checkout "$BRANCH"
    sudo git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH"
    log "       Repo actualizado (rama $BRANCH)."
else
    sudo git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
    log "       Repo clonado (rama $BRANCH)."
fi
sudo chown -R "$(id -u):$(id -g)" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/deploy/node-agent-lan.sh"

log "[4/5] Configurando firewall..."
configure_firewall

log "[5/5] Instalando servicio pda-agent-lan..."
sudo mkdir -p /var/lib/pda-cluster
echo "PDA_REGISTRY=$REGISTRY" | sudo tee /var/lib/pda-cluster/config.env > /dev/null
sudo cp "$INSTALL_DIR/deploy/pda-agent-lan.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable pda-agent-lan
sudo systemctl restart pda-agent-lan

echo ""
echo "┌──────────────────────────────────────────────┐"
echo "│   Bootstrap completado                        │"
echo "└──────────────────────────────────────────────┘"
echo ""
echo "El agente está corriendo. Ver progreso:"
echo "  sudo journalctl -fu pda-agent-lan"
echo ""
echo "Estado del cluster (cuando esté listo):"
echo "  curl -s http://localhost:9999/state.json | jq ."
echo ""
echo "El cluster arranca solo cuando hay 3 nodos en la subred."
echo ""
