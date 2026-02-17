import pika
import json
import os

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")

def publish_event(event_type, data):
    try:
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host=RABBITMQ_HOST)
        )
        channel = connection.channel()

        # Declarar exchange DURABLE
        channel.exchange_declare(
            exchange='events',
            exchange_type='fanout',
            durable=True
        )

        message = {
            "event": event_type,
            "data": data
        }

        channel.basic_publish(
            exchange='events',
            routing_key='',
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=2  # Hace el mensaje persistente
            )
        )

        print("📤 Event published:", message)

        connection.close()

    except Exception as e:
        print("❌ Error publishing event:", e)
