import json
import os

import pika


def _get_channel():
    url = os.getenv("RABBITMQ_URL", "amqp://admin:admin_password_segura@localhost:5672/")
    connection = pika.BlockingConnection(pika.URLParameters(url))
    channel = connection.channel()
    channel.queue_declare(queue="pdf_processing", durable=True)
    return connection, channel


def enqueue_pdf(document_id: int, object_key: str) -> None:
    connection, channel = _get_channel()
    channel.basic_publish(
        exchange="",
        routing_key="pdf_processing",
        body=json.dumps({"document_id": document_id, "object_key": object_key}),
        properties=pika.BasicProperties(delivery_mode=2),
    )
    connection.close()
