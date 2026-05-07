import logging
import os
import time
from contextlib import asynccontextmanager

import psycopg2
from fastapi import FastAPI

from app.api.endpoints import router
from app.api.monitor import router as monitor_router
from app.core.jwt_connections import hash_password
from app.db.sql_connections import SessionLocal, User, create_tables
from app.db.services.minio_connection import ensure_bucket

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


def _seed_admin() -> None:
    """Crea el usuario admin por defecto si no existe ningún admin en la BD."""
    username = os.getenv("ADMIN_USERNAME", "admin")
    password = os.getenv("ADMIN_PASSWORD", "admin1234")
    db = SessionLocal()
    try:
        if not db.query(User).filter(User.is_admin.is_(True)).first():
            db.add(User(username=username, password_hash=hash_password(password), is_admin=True))
            db.commit()
            log.info("Admin user '%s' created.", username)
    except Exception as e:
        log.warning("Could not seed admin user: %s", e)
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    _wait_for_db()
    _seed_admin()
    _wait_for_minio()
    yield


app = FastAPI(title="ScienClassifier API", lifespan=lifespan)
app.include_router(router, prefix="/api")
app.include_router(monitor_router, prefix="/api")
