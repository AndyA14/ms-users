import pika
import json
import time
from app.config import RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_USER, RABBITMQ_PASS
from app.mongo_logger import log_event

EXCHANGE_NAME = "events"
MAX_RETRIES   = 5
RETRY_DELAY   = 3  # segundos entre intentos


def _get_connection() -> pika.BlockingConnection:
    """
    Crea una conexión con reintentos.
    Util al arrancar cuando RabbitMQ aún no está listo.
    """
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    params = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        heartbeat=60,
        blocked_connection_timeout=30,
    )

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            return pika.BlockingConnection(params)
        except pika.exceptions.AMQPConnectionError as e:
            print(f"⏳ RabbitMQ not ready (attempt {attempt}/{MAX_RETRIES}): {e}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_DELAY)

    raise RuntimeError("❌ Could not connect to RabbitMQ after max retries.")


def publish_event(event_type: str, data: dict):
    """
    Publica un evento en el exchange 'events' (fanout, durable).
    Registra el evento en MongoDB como audit log.
    """
    message = {"event": event_type, "data": data}

    try:
        connection = _get_connection()
        channel = connection.channel()

        channel.exchange_declare(
            exchange=EXCHANGE_NAME,
            exchange_type="fanout",
            durable=True,
        )

        channel.basic_publish(
            exchange=EXCHANGE_NAME,
            routing_key="",
            body=json.dumps(message),
            properties=pika.BasicProperties(delivery_mode=2),  # persistente
        )

        print(f"📤 Event published: {event_type}")
        connection.close()

        # ── Audit log en Mongo ────────────────────────────────────────────────
        log_event(event_type=event_type, payload=data, direction="OUT")

    except Exception as e:
        print(f"❌ Error publishing event [{event_type}]: {e}")
        # Re-raise para que el endpoint retorne 500 en lugar de perder el evento
        raise