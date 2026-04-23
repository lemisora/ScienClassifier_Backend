import json
import logging
import os
import time

import pika
import pdfplumber
from io import BytesIO

from app.db.sql_connections import Document, DocumentCategory, SessionLocal
from app.services.minio_connection import get_client, BUCKET
from worker.classifier import classify

logging.basicConfig(level=logging.INFO, format="%(asctime)s [worker] %(message)s")
log = logging.getLogger(__name__)

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://admin:admin_password_segura@localhost:5672/")
QUEUE = "pdf_processing"
RETRY_DELAY = 5


def process(body: bytes) -> None:
    msg = json.loads(body)
    document_id = msg["document_id"]
    object_key = msg["object_key"]

    log.info(f"Procesando documento {document_id} ({object_key})")

    # Descargar PDF de MinIO
    response = get_client().get_object(BUCKET, object_key)
    pdf_bytes = response.read()
    response.close()

    # Extraer texto
    with pdfplumber.open(BytesIO(pdf_bytes)) as pdf:
        text = "\n".join(page.extract_text() or "" for page in pdf.pages).strip()

    # Clasificar
    result = classify(text)

    # Guardar en PostgreSQL
    db = SessionLocal()
    try:
        doc = db.query(Document).filter(Document.id == document_id).first()
        if not doc:
            log.warning(f"Documento {document_id} no encontrado en DB, descartando")
            return

        doc.status = "processing"
        db.commit()

        doc.title = result["title"] or doc.filename
        doc.authors = result["authors"]
        doc.year = result["year"]

        db.query(DocumentCategory).filter(DocumentCategory.document_id == document_id).delete()
        for cat in result["categories"]:
            db.add(DocumentCategory(
                document_id=document_id,
                category=cat["category"],
                score=int(cat["score"] * 100),
            ))

        doc.status = "done"
        db.commit()
        log.info(f"Documento {document_id} clasificado: {[c['category'] for c in result['categories']]}")
    except Exception as e:
        doc.status = "error"
        db.commit()
        raise
    finally:
        db.close()


def start() -> None:
    while True:
        try:
            connection = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
            channel = connection.channel()
            channel.queue_declare(queue=QUEUE, durable=True)
            channel.basic_qos(prefetch_count=1)

            def callback(ch, method, properties, body):
                try:
                    process(body)
                    ch.basic_ack(delivery_tag=method.delivery_tag)
                except Exception as e:
                    log.error(f"Error procesando mensaje: {e}")
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

            channel.basic_consume(queue=QUEUE, on_message_callback=callback)
            log.info("Worker listo, esperando mensajes...")
            channel.start_consuming()

        except pika.exceptions.AMQPConnectionError:
            log.warning(f"RabbitMQ no disponible, reintentando en {RETRY_DELAY}s...")
            time.sleep(RETRY_DELAY)


if __name__ == "__main__":
    start()
