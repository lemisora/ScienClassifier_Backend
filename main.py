import logging
import os
import time
from contextlib import asynccontextmanager

import psycopg2
from fastapi import FastAPI

from app.api.endpoints import router
from app.db.sql_connections import create_tables
from app.services.minio_connection import ensure_bucket

log = logging.getLogger(__name__)


def _fix_admin_login() -> None:
    """Garantiza que el usuario 'admin' de Patroni tenga LOGIN.
    Spilo lo crea sin ese atributo; esto se auto-repara en cada arranque."""
    db_url = os.getenv("DATABASE_URL", "")
    import re
    m = re.match(r"postgresql(?:\+psycopg2)?://([^:]+):([^@]+)@(.+)/([^?]+)", db_url)
    if not m:
        return
    _, _, hostpart, dbname = m.groups()
    hosts = [h.split(":")[0].strip() for h in hostpart.split(",")]
    for host in hosts:
        try:
            conn = psycopg2.connect(
                host=host, port=5432, dbname="postgres",
                user="postgres", password="postgres",
                connect_timeout=5,
            )
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute("ALTER USER admin WITH LOGIN SUPERUSER PASSWORD 'lofi_admin';")
            conn.close()
            log.info("admin LOGIN ensured via %s", host)
            return
        except Exception as e:
            log.debug("fix_admin_login via %s: %s", host, e)


def _wait_for_db(retries: int = 60, delay: int = 5) -> None:
    _fix_admin_login()
    for attempt in range(1, retries + 1):
        try:
            create_tables()
            return
        except Exception as e:
            log.warning("DB not ready (attempt %d/%d): %s", attempt, retries, e)
            if attempt == retries:
                raise
            time.sleep(delay)


def _wait_for_minio(retries: int = 60, delay: int = 5) -> None:
    for attempt in range(1, retries + 1):
        try:
            ensure_bucket()
            return
        except Exception as e:
            log.warning("MinIO not ready (attempt %d/%d): %s", attempt, retries, e)
            if attempt == retries:
                raise
            time.sleep(delay)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _wait_for_db()
    _wait_for_minio()
    yield


app = FastAPI(title="ScienClassifier API", lifespan=lifespan)
app.include_router(router, prefix="/api")
