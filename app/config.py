import os

# Server
PORT = int(os.getenv("PORT", 8001))

# RabbitMQ
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", 5672))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.getenv("RABBITMQ_PASS", "guest")

# PostgreSQL — transaccional
POSTGRES_URL = os.getenv(
    "POSTGRES_URL",
    "postgresql://postgres:postgres@localhost:5432/ms_users"
)

# MongoDB — event log / audit
MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")
MONGO_DB   = os.getenv("MONGO_DB", "events_log")