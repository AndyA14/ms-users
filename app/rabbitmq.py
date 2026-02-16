import pika
import json
import os

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")

def publish_event(event_type, data):
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=RABBITMQ_HOST)
    )
    channel = connection.channel()

    channel.exchange_declare(exchange='events', exchange_type='fanout')

    message = {
        "event": event_type,
        "data": data
    }

    channel.basic_publish(
        exchange='events',
        routing_key='',
        body=json.dumps(message)
    )

    connection.close()
