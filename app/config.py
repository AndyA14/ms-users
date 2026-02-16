import os

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
PORT = int(os.getenv("PORT", 8001))
