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
_PATRONI_PORT = 8008
_RMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq1")
_RMQ_PORT = 15672
_RMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER", "admin")
_RMQ_PASS = os.getenv("RABBITMQ_DEFAULT_PASS", "admin_password_segura")
_RMQ_QUEUE = "pdf_processing"


def _db_stats() -> dict:
    db = SessionLocal()
    try:
        total_users = db.query(User).count()
        total_docs = db.query(Document).count()
        by_status = {
            s: db.query(Document).filter(Document.status == s).count()
            for s in ("pending", "processing", "done", "error")
        }
        return {"total_users": total_users, "total_documents": total_docs, "by_status": by_status}
    finally:
        db.close()


async def _rabbitmq_stats() -> dict:
    url = f"http://{_RMQ_HOST}:{_RMQ_PORT}/api/queues/%2F/{_RMQ_QUEUE}"
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(url, auth=(_RMQ_USER, _RMQ_PASS))
            if r.status_code == 200:
                d = r.json()
                return {
                    "messages": d.get("messages", 0),
                    "messages_ready": d.get("messages_ready", 0),
                    "messages_unacknowledged": d.get("messages_unacknowledged", 0),
                    "consumers": d.get("consumers", 0),
                    "ok": True,
                }
    except Exception:
        pass
    return {"messages": 0, "messages_ready": 0, "messages_unacknowledged": 0, "consumers": 0, "ok": False}


async def _patroni_stats() -> dict:
    for host in _PATRONI_HOSTS:
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"http://{host}:{_PATRONI_PORT}/cluster")
                if r.status_code == 200:
                    data = r.json()
                    leader = None
                    replicas = []
                    for m in data.get("members", []):
                        node = {
                            "host": m.get("name", "?"),
                            "role": m.get("role", "unknown"),
                            "state": m.get("state", "unknown"),
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


async def _snapshot() -> dict:
    db_stats, rmq, patroni = await asyncio.gather(
        asyncio.to_thread(_db_stats),
        _rabbitmq_stats(),
        _patroni_stats(),
    )
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "db": db_stats,
        "rabbitmq": rmq,
        "patroni": patroni,
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
