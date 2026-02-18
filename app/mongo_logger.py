from pymongo import MongoClient
from datetime import datetime, timezone
from app.config import MONGO_URL, MONGO_DB

_client: MongoClient | None = None


def _get_collection():
    global _client
    if _client is None:
        _client = MongoClient(MONGO_URL, serverSelectionTimeoutMS=3000)
    return _client[MONGO_DB]["event_log"]


def log_event(event_type: str, payload: dict, direction: str = "OUT"):
    """
    Guarda cada evento emitido o recibido en MongoDB.

    direction = "OUT" → evento que este servicio publicó
    direction = "IN"  → evento que este servicio consumió
    """
    try:
        doc = {
            "service":    "ms-users",
            "direction":  direction,
            "event":      event_type,
            "payload":    payload,
            "created_at": datetime.now(timezone.utc),
        }
        _get_collection().insert_one(doc)
        print(f"📋 Event logged to MongoDB [{direction}]: {event_type}")
    except Exception as e:
        # El log nunca debe bloquear el flujo principal
        print(f"⚠️  Could not log event to MongoDB: {e}")