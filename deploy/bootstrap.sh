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
#   - Instala jq, git, curl, just
#   - Clona / actualiza el repo en /opt/scienclassifier
#   - Abre los puertos necesarios en UFW (si está activo)
#   - Instala y arranca el servicio pda-agent (systemd)
#
# El agente detecta automáticamente los otros nodos y forma
# el cluster. Ver logs con:  sudo journalctl -fu pda-agent
# ============================================================

set -euo pipefail

# ── Configuración ─────────────────────────────────────────
# Usuario de Docker Hub donde están las imágenes del proyecto.
# El agente usa esto al generar el .env.
REGISTRY="pdanodos"

REPO_URL="https://github.com/lemisora/ScienClassifier_Backend.git"
INSTALL_DIR="/opt/scienclassifier"
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

# ── [2/5] Clonar o actualizar repo ───────────────────────
log "[3/5] Preparando repositorio en $INSTALL_DIR..."
if [[ -d "$INSTALL_DIR/.git" ]]; then
    sudo git -C "$INSTALL_DIR" pull --ff-only origin main
    log "       Repo actualizado."
else
    sudo git clone --branch testing_VMs_tailscale "$REPO_URL" "$INSTALL_DIR"
    log "       Repo clonado."
fi
sudo chown -R "$(id -u):$(id -g)" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/deploy/node-agent.sh"

# ── [3/5] Guardar configuración del agente ───────────────
log "[4/5] Guardando configuración del agente..."
sudo mkdir -p /var/lib/pda-cluster
echo "PDA_REGISTRY=$REGISTRY" | sudo tee /var/lib/pda-cluster/config.env > /dev/null

# ── [4/5] Abrir puertos en UFW ───────────────────────────
if command -v ufw &>/dev/null && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    log "       Configurando UFW..."
    sudo ufw allow in on tailscale0      comment "Tailscale (todo)" 2>/dev/null || true
    sudo ufw allow 2377/tcp              comment "Docker Swarm control"
    sudo ufw allow 7946/tcp              comment "Docker Swarm gossip TCP"
    sudo ufw allow 7946/udp              comment "Docker Swarm gossip UDP"
    sudo ufw allow 4789/udp              comment "Docker overlay VXLAN"
    sudo ufw allow 9999/tcp              comment "PDA agent state API"
    sudo ufw reload
    log "       UFW configurado."
else
    log "       UFW no activo — saltando reglas de firewall."
fi

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
echo "IMPORTANTE si este nodo será el manager:"
echo "  Asegurarte de haber hecho 'docker login -u $REGISTRY' antes."
echo "  El manager es el nodo con la IP Tailscale más baja."
echo ""
echo "El cluster arranca solo cuando hay $((3)) nodos conectados a Tailscale."
