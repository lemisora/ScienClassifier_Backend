import os
from datetime import timedelta
from io import BytesIO

from minio import Minio
from minio.deleteobjects import DeleteObject
from minio.error import S3Error

_client: Minio | None = None

BUCKET = os.getenv("MINIO_BUCKET", "scientific-papers")


def get_client() -> Minio:
    global _client
    if _client is None:
        _client = Minio(
            endpoint=os.getenv("MINIO_ENDPOINT", "minio1:9000"),
            access_key=os.getenv("MINIO_ACCESS_KEY"),
            secret_key=os.getenv("MINIO_SECRET_KEY"),
            secure=False,
        )
    return _client


def ensure_bucket() -> None:
    client = get_client()
    if not client.bucket_exists(BUCKET):
        client.make_bucket(BUCKET)


def upload_pdf(user_id: int, filename: str, data: bytes) -> str:
    """Sube un PDF al bucket y devuelve la object key."""
    client = get_client()
    key = f"user_{user_id}/{filename}"
    client.put_object(
        bucket_name=BUCKET,
        object_name=key,
        data=BytesIO(data),
        length=len(data),
        content_type="application/pdf",
    )
    return key


def get_presigned_url(object_key: str, expires_hours: int = 1) -> str:
    """Devuelve una URL firmada temporal para descargar el objeto."""
    client = get_client()
    return client.presigned_get_object(
        bucket_name=BUCKET,
        object_name=object_key,
        expires=timedelta(hours=expires_hours),
    )


def delete_pdf(object_key: str) -> None:
    """Elimina un objeto del bucket."""
    client = get_client()
    client.remove_object(BUCKET, object_key)


def delete_pdfs(object_keys: list[str]) -> None:
    """Elimina múltiples objetos en una sola operación."""
    client = get_client()
    errors = client.remove_objects(
        BUCKET,
        [DeleteObject(key) for key in object_keys],
    )
    failed = [str(e) for e in errors]
    if failed:
        raise S3Error(f"No se pudieron eliminar: {failed}")
