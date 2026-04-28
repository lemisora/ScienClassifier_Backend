#!/usr/bin/env bash
# ============================================================
# PDA Node Agent — Autodescubrimiento y gestión del Swarm
# ============================================================
# Detecta todos los nodos de este proyecto en la red Tailscale,
# elige un manager por consenso (IP más baja), forma el cluster
# y despliega el stack automáticamente.
#
# Reglas de quorum:
#   • Mínimo 3 nodos para arrancar.
#   • Nodos adicionales se admiten en pares:
#       3 activos + 1 nuevo  → espera el par
#       3 activos + 2 nuevos → ambos se admiten juntos (total 5)
#   Así el total de managers siempre es impar (3, 5, 7...)
#   y el quorum de Raft se mantiene.
#
# No toca nada fuera de:
#   /opt/scienclassifier     (repo del proyecto)
#   /var/lib/pda-cluster     (estado y config del agente)
# ============================================================

set -euo pipefail

# ── Configuración ─────────────────────────────────────────
INSTALL_DIR="/opt/scienclassifier"
STATE_DIR="/var/lib/pda-cluster"
STATE_FILE="$STATE_DIR/state.json"
CONFIG_FILE="$STATE_DIR/config.env"
STATE_PORT=9999
MIN_NODES=3
POLL=15          # segundos entre cada chequeo
LOG_TAG="pda-agent"

# ── Logging ───────────────────────────────────────────────
ts()   { date '+%H:%M:%S'; }
log()  { echo "$(ts) INFO  $*"; logger -t "$LOG_TAG" -- "$*" 2>/dev/null || true; }
warn() { echo "$(ts) WARN  $*" >&2; logger -t "$LOG_TAG" -p user.warning -- "$*" 2>/dev/null || true; }
die()  { echo "$(ts) ERROR $*" >&2; logger -t "$LOG_TAG" -p user.err    -- "$*" 2>/dev/null || true; exit 1; }

# ── Cargar config ─────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
PDA_REGISTRY="${PDA_REGISTRY:-xavierhuerta}"

# ── Tailscale helpers ─────────────────────────────────────
ts_status()    { tailscale status --json 2>/dev/null; }
ts_self_name() { ts_status | jq -r '.Self.HostName'; }
ts_self_ip()   { ts_status | jq -r '.Self.TailscaleIPs[0]'; }

# Devuelve [{hostname, ip}] de todos los nodos online, ordenados por IP.
# El primer elemento (menor IP) será siempre el manager.
ts_nodes() {
    ts_status | jq -c '
        [.Self] + (.Peer // {} | to_entries | map(.value) | map(select(.Online == true)))
        | map({ hostname: .HostName, ip: .TailscaleIPs[0] })
        | sort_by(.ip)
    '
}

ts_count()   { ts_nodes | jq 'length'; }
ts_manager() { ts_nodes | jq -r 'first.hostname'; }

# ── JSON utils ────────────────────────────────────────────
# Convierte lista de argumentos en JSON array de strings.
# Sin argumentos devuelve [].
arr_to_json() {
    if [[ $# -eq 0 ]]; then echo "[]"; return; fi
    printf '%s\n' "$@" | jq -Rcs 'split("\n") | map(select(. != ""))'
}

# Verifica si el JSON array $1 contiene la string $2.
json_has() { jq -e --arg v "$2" 'contains([$v])' <<< "$1" > /dev/null 2>&1; }

# ── Estado compartido ─────────────────────────────────────
# El manager escribe state.json y lo sirve en :9999.
# Los workers lo leen para saber cuándo y cómo unirse.
#
# Formato de state.json:
# {
#   "manager_ip":       "100.x.x.x",
#   "manager_hostname": "node-1",
#   "active_nodes":     ["node-1","node-2","node-3"],
#   "pending_nodes":    ["node-4"],   ← espera su par
#   "worker_token":     "SWMTKN-...",
#   "manager_token":    "SWMTKN-...",
#   "swarm_initialized": true,
#   "stack_deployed":   true
# }

write_state() {
    local manager_ip="$1" manager_hn="$2"
    local active="$3"    pending="$4"
    local wtoken="$5"    mtoken="$6"
    local swarm="${7:-false}" deployed="${8:-false}"

    jq -n \
        --arg     manager_ip       "$manager_ip"  \
        --arg     manager_hostname "$manager_hn"  \
        --argjson active           "$active"      \
        --argjson pending          "$pending"     \
        --arg     worker_token     "$wtoken"      \
        --arg     manager_token    "$mtoken"      \
        --argjson swarm_init       "$swarm"       \
        --argjson deployed         "$deployed"    \
        '{
            manager_ip:        $manager_ip,
            manager_hostname:  $manager_hostname,
            active_nodes:      $active,
            pending_nodes:     $pending,
            worker_token:      $worker_token,
            manager_token:     $manager_token,
            swarm_initialized: $swarm_init,
            stack_deployed:    $deployed
        }' > "$STATE_FILE"
}

# Servidor HTTP mínimo que sirve state.json en STATE_PORT.
serve_state() {
    pkill -f "pda-state-server" 2>/dev/null || true
    sleep 1
    python3 - <<'PYEOF' &
import http.server, pathlib, os

STATE = "/var/lib/pda-cluster/state.json"
PORT  = 9999

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/state.json":
            try:
                data = pathlib.Path(STATE).read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(data)
            except Exception:
                self.send_response(500)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, *_): pass   # silenciar logs HTTP

os.setpgrp()
http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
PYEOF
    log "State server escuchando en :$STATE_PORT"
}

get_remote_state() {
    local ip="$1"
    curl -sf --max-time 5 "http://$ip:$STATE_PORT/state.json"
}

# ══════════════════════════════════════════════════════════
# MANAGER
# ══════════════════════════════════════════════════════════

mgr_wait_quorum() {
    log "Esperando quorum: necesito ≥$MIN_NODES nodos con total impar..."
    while true; do
        local nodes count
        nodes=$(ts_nodes)
        count=$(echo "$nodes" | jq 'length')

        if (( count >= MIN_NODES && count % 2 == 1 )); then
            log "Quorum alcanzado: $count nodos"
            echo "$nodes"
            return
        elif (( count >= MIN_NODES && count % 2 == 0 )); then
            warn "Hay $count nodos (número par). Esperando 1 más para quorum impar..."
        else
            log "Nodos online: $count / $MIN_NODES mínimo"
        fi
        sleep "$POLL"
    done
}

mgr_init_swarm() {
    local ip="$1"
    if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
        log "Swarm ya activo — saltando init."
        return
    fi
    log "Inicializando Docker Swarm en $ip..."
    docker swarm init --advertise-addr "$ip"
    log "Swarm inicializado."
}

mgr_gen_env() {
    local nodes_json="$1" manager_ip="$2"

    local n1 n2 n3 wtoken mtoken
    n1=$(echo "$nodes_json" | jq -r '.[0].hostname')
    n2=$(echo "$nodes_json" | jq -r '.[1].hostname')
    n3=$(echo "$nodes_json" | jq -r '.[2].hostname')
    wtoken=$(docker swarm join-token worker  -q)
    mtoken=$(docker swarm join-token manager -q)

    # Partir de .env.example y sobreescribir solo las variables dinámicas
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"

    local -A overrides=(
        [MANAGER_IP]="$manager_ip"
        [NODE1_HOSTNAME]="$n1"
        [NODE2_HOSTNAME]="$n2"
        [NODE3_HOSTNAME]="$n3"
        [SWARM_WORKER_TOKEN]="$wtoken"
        [SWARM_MANAGER_TOKEN]="$mtoken"
        [REGISTRY]="$PDA_REGISTRY"
    )

    for key in "${!overrides[@]}"; do
        local val="${overrides[$key]}"
        if grep -q "^${key}=" "$INSTALL_DIR/.env"; then
            sed -i "s|^${key}=.*|${key}=${val}|" "$INSTALL_DIR/.env"
        else
            echo "${key}=${val}" >> "$INSTALL_DIR/.env"
        fi
    done

    log ".env generado: nodos $n1 / $n2 / $n3  |  manager $manager_ip  |  registry $PDA_REGISTRY"
}

mgr_label_node() {
    local hostname="$1"
    docker node update --label-add etcd=true  "$hostname" 2>/dev/null || true
    docker node update --label-add minio=true "$hostname" 2>/dev/null || true
    log "Labels etcd+minio asignados a: $hostname"
}

mgr_wait_all_joined() {
    local expected="$1"
    log "Esperando que los $expected nodos entren al Swarm..."
    while true; do
        local n; n=$(docker node ls -q 2>/dev/null | wc -l)
        log "  Swarm: $n / $expected"
        (( n >= expected )) && break
        sleep 5
    done
}

run_as_manager() {
    local my_hn="$1" my_ip="$2"
    log "════════════════════════════════════"
    log "ROL: MANAGER  ($my_hn @ $my_ip)"
    log "════════════════════════════════════"

    mkdir -p "$STATE_DIR"

    # ── Fase 1: esperar quorum impar ─────────────────────
    local nodes; nodes=$(mgr_wait_quorum)
    local count;  count=$(echo "$nodes" | jq 'length')
    local active_json; active_json=$(echo "$nodes" | jq '[.[].hostname]')

    # ── Fase 2: inicializar Swarm ────────────────────────
    mgr_init_swarm "$my_ip"
    local wtoken mtoken
    wtoken=$(docker swarm join-token worker  -q)
    mtoken=$(docker swarm join-token manager -q)

    # ── Fase 3: generar .env ─────────────────────────────
    mgr_gen_env "$nodes" "$my_ip"

    # ── Fase 4: publicar estado y servir ─────────────────
    # Desde este momento los workers pueden leer el estado y unirse.
    write_state "$my_ip" "$my_hn" "$active_json" "[]" \
        "$wtoken" "$mtoken" "true" "false"
    serve_state

    # ── Fase 5: esperar que todos se unan ────────────────
    mgr_wait_all_joined "$count"

    # ── Fase 6: etiquetar los 3 nodos iniciales ──────────
    # Solo los 3 primeros corren etcd+minio (servicios con estado).
    while IFS= read -r h; do mgr_label_node "$h"; done \
        < <(echo "$nodes" | jq -r '.[].hostname')

    # ── Fase 7: desplegar stack ──────────────────────────
    log "Desplegando stack ScienClassifier..."
    cd "$INSTALL_DIR"
    just deploy

    write_state "$my_ip" "$my_hn" "$active_json" "[]" \
        "$wtoken" "$mtoken" "true" "true"

    log "════════════════════════════════════"
    log "Stack desplegado. Cluster con $count nodos activo."
    log "════════════════════════════════════"

    # ── Fase 8: discovery loop ───────────────────────────
    # Detecta nuevos nodos en la tailnet y los admite en pares
    # para mantener el total de managers impar (quorum Raft).
    #
    # Nodos nuevos (≥4): no corren etcd/minio (están anclados a los 3 iniciales),
    # pero sí reciben fastapi + worker + nginx automáticamente (mode: global).
    local -a active=() pending=()
    while IFS= read -r h; do active+=("$h"); done \
        < <(echo "$nodes" | jq -r '.[].hostname')

    log "Discovery loop activo. Esperando nuevos nodos..."
    while true; do
        sleep "$POLL"

        # Detectar nodos Tailscale que no están registrados aún
        while IFS= read -r h; do
            local seen=false
            for x in "${active[@]}" "${pending[@]:+${pending[@]}}"; do
                [[ "$x" == "$h" ]] && seen=true && break
            done
            $seen && continue
            log "Nuevo nodo detectado: '$h' → en cola pendiente (esperando par)"
            pending+=("$h")
        done < <(ts_nodes | jq -r '.[].hostname')

        # Mostrar advertencia si hay un nodo esperando su par
        if (( ${#pending[@]} == 1 )); then
            warn "1 nodo pendiente ('${pending[0]}'). Se admitirá cuando llegue su par."
        fi

        # Admitir de a 2 para mantener total impar
        while (( ${#pending[@]} >= 2 )); do
            local p1="${pending[0]}" p2="${pending[1]}"
            pending=("${pending[@]:2}")
            active+=("$p1" "$p2")

            log "Admitiendo par: $p1 + $p2  (total activos: ${#active[@]})"
            sleep 8  # dar tiempo al join-swarm del worker
            docker node promote "$p1" 2>/dev/null || warn "No se pudo promover $p1 (¿aún no unido?)"
            docker node promote "$p2" 2>/dev/null || warn "No se pudo promover $p2"
            log "Nodos $p1 y $p2 promovidos a Swarm manager."
        done

        # Actualizar state.json
        local aj pj
        aj=$(arr_to_json "${active[@]:+${active[@]}}")
        pj=$(arr_to_json "${pending[@]:+${pending[@]}}")
        write_state "$my_ip" "$my_hn" "$aj" "$pj" \
            "$wtoken" "$mtoken" "true" "true"
    done
}

# ══════════════════════════════════════════════════════════
# WORKER
# ══════════════════════════════════════════════════════════

run_as_worker() {
    local my_hn="$1"
    log "════════════════════════════════════"
    log "ROL: WORKER  ($my_hn)"
    log "════════════════════════════════════"

    # Manager = nodo con la IP Tailscale más baja
    local manager_ip; manager_ip=$(ts_nodes | jq -r 'first.ip')
    log "Manager estimado: $manager_ip"

    # Esperar que el state server del manager esté disponible
    log "Esperando state server del manager ($manager_ip:$STATE_PORT)..."
    local t=0
    until get_remote_state "$manager_ip" > /dev/null 2>&1; do
        (( t++ % 4 == 0 )) && log "  Polling $manager_ip:$STATE_PORT..."
        sleep "$POLL"
    done
    log "State server disponible."

    # Bucle hasta ser admitido en el Swarm
    while true; do
        local state; state=$(get_remote_state "$manager_ip")
        local swarm_init; swarm_init=$(echo "$state" | jq -r '.swarm_initialized // "false"')

        if [[ "$swarm_init" != "true" ]]; then
            log "Swarm aún no inicializado. Esperando..."; sleep "$POLL"; continue
        fi

        local active pending
        active=$(echo "$state"  | jq '.active_nodes')
        pending=$(echo "$state" | jq '.pending_nodes')

        if json_has "$active" "$my_hn"; then
            # El manager me admitió → unirme al Swarm
            if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
                log "Ya estoy en el Swarm."
                break
            fi
            local wtoken real_manager_ip
            wtoken=$(echo "$state"         | jq -r '.worker_token')
            real_manager_ip=$(echo "$state" | jq -r '.manager_ip')
            log "Soy activo — uniéndome al Swarm en $real_manager_ip..."
            docker swarm join --token "$wtoken" "$real_manager_ip:2377"
            log "Unido al Swarm exitosamente."
            break

        elif json_has "$pending" "$my_hn"; then
            local pcount; pcount=$(echo "$state" | jq '.pending_nodes | length')
            warn "En cola pendiente ($pcount/2 para formar par). Esperando..."

        else
            log "No aparezco en el estado del manager todavía. Esperando..."
        fi

        sleep "$POLL"
    done

    # Esperar que el stack esté desplegado para confirmar en logs
    log "Esperando que el stack quede desplegado..."
    until [[ "$(get_remote_state "$manager_ip" | jq -r '.stack_deployed // "false"')" == "true" ]]; do
        sleep "$POLL"
    done

    log "════════════════════════════════════"
    log "Nodo operativo."
    log "fastapi + worker + nginx corren aquí automáticamente (mode: global)."
    log "etcd / patroni / minio solo corren en los 3 nodos iniciales."
    log "════════════════════════════════════"

    # Mantener vivo: re-unirse si el Swarm se cae (ej: reinicio del manager)
    while true; do
        sleep 60
        if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
            warn "Perdí conexión al Swarm. Reintentando en $POLL s..."
            sleep "$POLL"
            # Systemd lo va a reiniciar si `exit 1`
            exit 1
        fi
    done
}

# ══════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════

main() {
    log "PDA Node Agent arrancando..."

    # Esperar Tailscale
    local t=0
    until tailscale status &>/dev/null; do
        (( ++t > 24 )) && die "Tailscale no disponible tras 2 min."
        log "Esperando Tailscale... ($t)"; sleep 5
    done

    # Esperar Docker
    t=0
    until docker info &>/dev/null; do
        (( ++t > 24 )) && die "Docker no disponible tras 2 min."
        log "Esperando Docker... ($t)"; sleep 5
    done

    local my_hn my_ip
    my_hn=$(ts_self_name)
    my_ip=$(ts_self_ip)
    log "Nodo: $my_hn  |  IP Tailscale: $my_ip"

    # Esperar MIN_NODES nodos antes de elegir rol.
    # Esto garantiza que todos ven el mismo conjunto de nodos
    # al momento de la elección y eligen el mismo manager.
    log "Buscando nodos en la tailnet (mínimo $MIN_NODES)..."
    until (( $(ts_count) >= MIN_NODES )); do
        log "  Online: $(ts_count) / $MIN_NODES"
        sleep "$POLL"
    done

    # Elección: IP más baja = manager (determinístico, sin coordinación)
    local manager_hn; manager_hn=$(ts_manager)
    log "Manager elegido por consenso: $manager_hn"

    if [[ "$manager_hn" == "$my_hn" ]]; then
        run_as_manager "$my_hn" "$my_ip"
    else
        run_as_worker "$my_hn"
    fi
}

main "$@"
