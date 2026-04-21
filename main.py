import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.endpoints import router
from app.db.sql_connections import create_tables
from app.services.minio_connection import ensure_bucket

log = logging.getLogger(__name__)


def _wait_for_db(retries: int = 60, delay: int = 5) -> None:
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
