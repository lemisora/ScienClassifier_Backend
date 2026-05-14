import asyncio
import json
import os
from datetime import datetime, timezone

import httpx
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse

from app.core.jwt_connections import decode_token
from app.db.sql_connections import Document, SessionLocal, User

router = APIRouter()

_PATRONI_HOSTS = ["patroni1", "patroni2", "patroni3"]
_PATRONI_PORT  = 8008
_RMQ_HOST      = os.getenv("RABBITMQ_HOST", "rabbitmq1")
_RMQ_PORT      = 15672
_RMQ_USER      = os.getenv("RABBITMQ_DEFAULT_USER", "admin")
_RMQ_PASS      = os.getenv("RABBITMQ_DEFAULT_PASS", "admin_password_segura")
_RMQ_QUEUE     = "pdf_processing"
_MINIO_HOSTS   = ["minio1", "minio2", "minio3"]
_MINIO_PORT    = 9000
_MANAGER_IP    = os.getenv("MANAGER_IP", "")
_AGENT_PORT    = 9999


def _db_stats() -> dict:
    db = SessionLocal()
    try:
        total_users = db.query(User).count()
        total_docs  = db.query(Document).count()
        by_status   = {
            s: db.query(Document).filter(Document.status == s).count()
            for s in ("pending", "processing", "done", "error")
        }
        return {"total_users": total_users, "total_documents": total_docs, "by_status": by_status}
    finally:
        db.close()


async def _rabbitmq_stats() -> dict:
    empty = {"messages": 0, "messages_ready": 0, "messages_unacknowledged": 0,
             "consumers": 0, "nodes": [], "ok": False}
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            queue_url = f"http://{_RMQ_HOST}:{_RMQ_PORT}/api/queues/%2F/{_RMQ_QUEUE}"
            nodes_url = f"http://{_RMQ_HOST}:{_RMQ_PORT}/api/nodes"
            queue_r, nodes_r = await asyncio.gather(
                client.get(queue_url, auth=(_RMQ_USER, _RMQ_PASS)),
                client.get(nodes_url, auth=(_RMQ_USER, _RMQ_PASS)),
            )
            result = dict(empty)
            if queue_r.status_code == 200:
                d = queue_r.json()
                result.update({
                    "messages":               d.get("messages", 0),
                    "messages_ready":         d.get("messages_ready", 0),
                    "messages_unacknowledged":d.get("messages_unacknowledged", 0),
                    "consumers":              d.get("consumers", 0),
                    "ok": True,
                })
            if nodes_r.status_code == 200:
                result["nodes"] = [
                    {"name": n["name"].split("@")[-1], "running": n.get("running", False)}
                    for n in nodes_r.json()
                ]
            return result
    except Exception:
        return empty


async def _patroni_stats() -> dict:
    for host in _PATRONI_HOSTS:
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"http://{host}:{_PATRONI_PORT}/cluster")
                if r.status_code == 200:
                    data = r.json()
                    leader, replicas = None, []
                    for m in data.get("members", []):
                        node = {
                            "host":     m.get("name", "?"),
                            "role":     m.get("role", "unknown"),
                            "state":    m.get("state", "unknown"),
                            "timeline": m.get("timeline"),
                        }
                        if m.get("role") == "leader":
                            leader = node
                        else:
                            replicas.append(node)
                    return {"leader": leader, "replicas": replicas}
        except Exception:
            continue
    return {"leader": None, "replicas": []}


async def _minio_stats() -> dict:
    for host in _MINIO_HOSTS:
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"http://{host}:{_MINIO_PORT}/minio/health/cluster")
                return {"ok": r.status_code == 200}
        except Exception:
            continue
    return {"ok": False}


async def _agent_stats() -> dict:
    empty = {"active_nodes": [], "pending_nodes": [], "manager_hostname": "", "ok": False}
    if not _MANAGER_IP:
        return empty
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"http://{_MANAGER_IP}:{_AGENT_PORT}/state.json")
            if r.status_code == 200:
                data = r.json()
                return {
                    "active_nodes":     data.get("active_nodes", []),
                    "pending_nodes":    data.get("pending_nodes", []),
                    "manager_hostname": data.get("manager_hostname", ""),
                    "ok": True,
                }
    except Exception:
        pass
    return empty


async def _snapshot() -> dict:
    db_stats, rmq, patroni, minio, agent = await asyncio.gather(
        asyncio.to_thread(_db_stats),
        _rabbitmq_stats(),
        _patroni_stats(),
        _minio_stats(),
        _agent_stats(),
    )
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "db":        db_stats,
        "rabbitmq":  rmq,
        "patroni":   patroni,
        "minio":     minio,
        "cluster":   agent,
    }


@router.get("/admin/worker/status")
async def worker_status(token: str = Query(...)):
    payload = decode_token(token)
    if not payload.get("admin"):
        raise HTTPException(status_code=403, detail="Se requiere rol admin")

    db_stats, rmq = await asyncio.gather(
        asyncio.to_thread(_db_stats),
        _rabbitmq_stats(),
    )
    setting = SessionLocal()
    try:
        from app.db.sql_connections import Setting
        s = setting.query(Setting).filter(Setting.key == "classifier_mode").first()
        mode = s.value if s else "keyword"
    finally:
        setting.close()

    return {
        "classifier_mode":  mode,
        "workers_active":   rmq["consumers"],
        "queue_depth":      rmq["messages_ready"],
        "processing":       rmq["messages_unacknowledged"],
        "rabbitmq_ok":      rmq["ok"],
        "docs_pending":     db_stats["by_status"]["pending"],
        "docs_processing":  db_stats["by_status"]["processing"],
        "docs_done":        db_stats["by_status"]["done"],
        "docs_error":       db_stats["by_status"]["error"],
    }


@router.get("/admin/monitor/stream")
async def monitor_stream(token: str = Query(...)):
    payload = decode_token(token)
    if not payload.get("admin"):
        raise HTTPException(status_code=403, detail="Se requiere rol admin")

    async def _generate():
        while True:
            try:
                snap = await _snapshot()
                yield f"data: {json.dumps(snap)}\n\n"
            except Exception as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"
            await asyncio.sleep(5)

    return StreamingResponse(
        _generate(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
