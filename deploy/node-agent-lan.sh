#!/usr/bin/env bash
# ============================================================
# PDA Node Agent — LAN (sin Tailscale)
# ============================================================
# Versión LAN del agente de autodescubrimiento.
# En lugar de Tailscale, cada nodo levanta un servidor de anuncio
# en el ANNOUNCE_PORT (9998) y escanea la subred para encontrar
# a los demás. El resto del flujo (quorum, Swarm, deploy) es
# idéntico al node-agent.sh original.
#
# Prerequisitos:
#   - Docker corriendo
#   - Los 3 nodos en la misma subred /24
#   - Puerto 9998 y 9999 abiertos en el firewall
# ============================================================

set -euo pipefail

# ── Configuración ─────────────────────────────────────────
INSTALL_DIR="/opt/scienclassifier"
STATE_DIR="/var/lib/pda-cluster"
STATE_FILE="$STATE_DIR/state.json"
CONFIG_FILE="$STATE_DIR/config.env"
STATE_PORT=9999
ANNOUNCE_PORT=9998
MIN_NODES=3
POLL=15
LOG_TAG="pda-agent"

# ── Logging ───────────────────────────────────────────────
ts()   { date '+%H:%M:%S'; }
log()  { echo "$(ts) INFO  $*" >&2; logger -t "$LOG_TAG" -- "$*" 2>/dev/null || true; }
warn() { echo "$(ts) WARN  $*" >&2; logger -t "$LOG_TAG" -p user.warning -- "$*" 2>/dev/null || true; }
die()  { echo "$(ts) ERROR $*" >&2; logger -t "$LOG_TAG" -p user.err    -- "$*" 2>/dev/null || true; exit 1; }

# ── Cargar config ─────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
PDA_REGISTRY="${PDA_REGISTRY:-pdanodos}"

# ── LAN helpers ───────────────────────────────────────────

# IP propia en la interfaz con ruta por defecto
lan_self_ip() {
    ip route get 1.1.1.1 2>/dev/null | awk '/src/ { for(i=1;i<=NF;i++) if($i=="src") print $(i+1) }' | head -1
}

lan_self_name() { hostname; }

# Levanta un servidor HTTP mínimo en ANNOUNCE_PORT que responde
# con {"hostname":"...", "ip":"..."} para que otros nodos nos encuentren.
serve_announce() {
    local my_hn="$1" my_ip="$2"
    pkill -f "pda-announce-server" 2>/dev/null || true
    sleep 1
    python3 - <<PYEOF &
import http.server, json, os
DATA = json.dumps({"hostname": "$my_hn", "ip": "$my_ip"}).encode()
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(DATA)
    def log_message(self, *_): pass
os.setpgrp()
http.server.HTTPServer(("0.0.0.0", $ANNOUNCE_PORT), H).serve_forever()
PYEOF
    log "Announce server escuchando en :$ANNOUNCE_PORT"
}

# Escanea toda la subred /24 en paralelo buscando announce servers.
# Devuelve [{hostname, ip}] ordenado por IP (el primer elemento es el manager).
lan_nodes() {
    local subnet
    subnet=$(lan_self_ip | cut -d. -f1-3)
    local tmp_dir; tmp_dir=$(mktemp -d)

    # Escaneo paralelo: 254 curl con timeout corto
    for i in $(seq 1 254); do
        (
            local resp
            resp=$(curl -sf --max-time 0.5 "http://${subnet}.${i}:${ANNOUNCE_PORT}/" 2>/dev/null) || exit 0
            # Validar que sea JSON con hostname e ip antes de guardar
            echo "$resp" | jq -e '.hostname and .ip' > /dev/null 2>&1 || exit 0
            echo "$resp" > "${tmp_dir}/${i}.json"
        ) &
    done
    wait

    local results=()
    for f in "${tmp_dir}"/*.json; do
        [[ -f "$f" ]] && results+=("$(cat "$f")")
    done
    rm -rf "$tmp_dir"

    if [[ ${#results[@]} -gt 0 ]]; then
        printf '%s\n' "${results[@]}" \
            | jq -s 'sort_by(.ip | split(".") | map(tonumber))'
    else
        echo "[]"
    fi
}

lan_count()   { lan_nodes | jq 'length'; }
# El nodo con la IP más baja es el manager (determinístico, sin coordinación)
lan_manager() { lan_nodes | jq -r 'first.hostname'; }

# ── JSON utils ────────────────────────────────────────────
arr_to_json() {
    if [[ $# -eq 0 ]]; then echo "[]"; return; fi
    printf '%s\n' "$@" | jq -Rcs 'split("\n") | map(select(. != ""))'
}

json_has() { jq -e --arg v "$2" 'contains([$v])' <<< "$1" > /dev/null 2>&1; }

# ── Estado compartido ─────────────────────────────────────
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
    def log_message(self, *_): pass

os.setpgrp()
http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
PYEOF
    log "State server escuchando en :$STATE_PORT"
}

get_remote_state() {
    curl -sf --max-time 5 "http://$1:$STATE_PORT/state.json"
}

# ══════════════════════════════════════════════════════════
# MANAGER
# ══════════════════════════════════════════════════════════

mgr_wait_quorum() {
    log "Esperando quorum: necesito ≥$MIN_NODES nodos con total impar..."
    while true; do
        local nodes count
        nodes=$(lan_nodes)
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
    if [[ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)" == "active" ]]; then
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

mgr_init_db() {
    log "Esperando Patroni primary para inicializar usuario admin..."
    local attempt=0 max=30
    while (( attempt < max )); do
        local out
        out=$(cd "$INSTALL_DIR" && just db-init 2>&1) && {
            log "DB inicializada: $out"
            docker service update --force scienclassifier_fastapi >/dev/null 2>&1 || true
            log "FastAPI reiniciado."
            return 0
        }
        (( ++attempt ))
        log "Patroni aún no listo (intento $attempt/$max) — reintentando en 10s..."
        sleep 10
    done
    warn "db-init no tuvo éxito en 5 min. Correr manualmente: just db-init"
}

run_as_manager() {
    local my_hn="$1" my_ip="$2"
    log "════════════════════════════════════"
    log "ROL: MANAGER  ($my_hn @ $my_ip)"
    log "════════════════════════════════════"

    mkdir -p "$STATE_DIR"

    local nodes; nodes=$(mgr_wait_quorum)
    local count;  count=$(echo "$nodes" | jq 'length')
    local active_json; active_json=$(echo "$nodes" | jq '[.[].hostname]')

    mgr_init_swarm "$my_ip"
    local wtoken mtoken
    wtoken=$(docker swarm join-token worker  -q)
    mtoken=$(docker swarm join-token manager -q)

    mgr_gen_env "$nodes" "$my_ip"

    write_state "$my_ip" "$my_hn" "$active_json" "[]" \
        "$wtoken" "$mtoken" "true" "false"
    serve_state

    mgr_wait_all_joined "$count"

    while IFS= read -r h; do mgr_label_node "$h"; done \
        < <(echo "$nodes" | jq -r '.[].hostname')

    log "Desplegando stack ScienClassifier..."
    cd "$INSTALL_DIR"
    just deploy

    write_state "$my_ip" "$my_hn" "$active_json" "[]" \
        "$wtoken" "$mtoken" "true" "true"

    log "════════════════════════════════════"
    log "Stack desplegado. Cluster con $count nodos activo."
    log "════════════════════════════════════"

    mgr_init_db

    # Discovery loop — admite nuevos nodos en pares para mantener quorum impar
    local -a active=() pending=()
    while IFS= read -r h; do active+=("$h"); done \
        < <(echo "$nodes" | jq -r '.[].hostname')

    log "Discovery loop activo. Esperando nuevos nodos..."
    while true; do
        sleep "$POLL"

        while IFS= read -r h; do
            local seen=false
            for x in "${active[@]}" "${pending[@]:+${pending[@]}}"; do
                [[ "$x" == "$h" ]] && seen=true && break
            done
            $seen && continue
            log "Nuevo nodo detectado: '$h' → en cola pendiente"
            pending+=("$h")
        done < <(lan_nodes | jq -r '.[].hostname')

        if (( ${#pending[@]} == 1 )); then
            warn "1 nodo pendiente ('${pending[0]}'). Esperando su par."
        fi

        while (( ${#pending[@]} >= 2 )); do
            local p1="${pending[0]}" p2="${pending[1]}"
            pending=("${pending[@]:2}")
            active+=("$p1" "$p2")

            log "Admitiendo par: $p1 + $p2  (total activos: ${#active[@]})"
            sleep 8
            docker node promote "$p1" 2>/dev/null || warn "No se pudo promover $p1"
            docker node promote "$p2" 2>/dev/null || warn "No se pudo promover $p2"
        done

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

    # El manager es el primer nodo del escaneo (IP más baja)
    local manager_ip; manager_ip=$(lan_nodes | jq -r 'first.ip')
    log "Manager estimado: $manager_ip"

    log "Esperando state server del manager ($manager_ip:$STATE_PORT)..."
    until get_remote_state "$manager_ip" > /dev/null 2>&1; do
        log "  Polling $manager_ip:$STATE_PORT..."
        sleep "$POLL"
    done
    log "State server disponible."

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
            if [[ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)" == "active" ]]; then
                log "Ya estoy en el Swarm."
                break
            fi
            local mtoken real_manager_ip
            mtoken=$(echo "$state"          | jq -r '.manager_token')
            real_manager_ip=$(echo "$state" | jq -r '.manager_ip')
            log "Uniéndome al Swarm como manager en $real_manager_ip..."
            docker swarm join --token "$mtoken" "$real_manager_ip:2377"
            log "Unido al Swarm exitosamente."
            break

        elif json_has "$pending" "$my_hn"; then
            local pcount; pcount=$(echo "$state" | jq '.pending_nodes | length')
            warn "En cola pendiente ($pcount/2). Esperando..."
        else
            log "No aparezco en el estado del manager todavía. Esperando..."
        fi

        sleep "$POLL"
    done

    log "Esperando que el stack quede desplegado..."
    until [[ "$(get_remote_state "$manager_ip" | jq -r '.stack_deployed // "false"')" == "true" ]]; do
        sleep "$POLL"
    done

    log "════════════════════════════════════"
    log "Nodo operativo."
    log "════════════════════════════════════"

    while true; do
        sleep 60
        if [[ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)" != "active" ]]; then
            warn "Perdí conexión al Swarm. Reiniciando..."
            exit 1
        fi
    done
}

# ══════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════

main() {
    log "PDA Node Agent (LAN) arrancando..."

    # Esperar Docker
    local t=0
    until docker info &>/dev/null; do
        (( ++t > 24 )) && die "Docker no disponible tras 2 min."
        log "Esperando Docker... ($t)"; sleep 5
    done

    local my_hn my_ip
    my_hn=$(lan_self_name)
    my_ip=$(lan_self_ip)
    [[ -z "$my_ip" ]] && die "No se pudo detectar la IP LAN. ¿Hay ruta por defecto?"
    log "Nodo: $my_hn  |  IP LAN: $my_ip"

    # Anunciar presencia ANTES de escanear, para que otros nos encuentren
    serve_announce "$my_hn" "$my_ip"

    # Esperar MIN_NODES nodos antes de elegir rol
    log "Buscando nodos en la subred (mínimo $MIN_NODES)..."
    until (( $(lan_nodes | jq 'length') >= MIN_NODES )); do
        log "  Online: $(lan_nodes | jq 'length') / $MIN_NODES"
        sleep "$POLL"
    done

    # Elección: IP más baja = manager
    local manager_hn; manager_hn=$(lan_nodes | jq -r 'first.hostname')
    log "Manager elegido por consenso: $manager_hn"

    if [[ "$manager_hn" == "$my_hn" ]]; then
        run_as_manager "$my_hn" "$my_ip"
    else
        run_as_worker "$my_hn"
    fi
}

main "$@"
