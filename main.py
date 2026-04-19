from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.endpoints import router
from app.db.sql_connections import create_tables
from app.services.minio_connection import ensure_bucket


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_tables()
    ensure_bucket()
    yield


app = FastAPI(title="ScienClassifier API", lifespan=lifespan)
app.include_router(router, prefix="/api")
