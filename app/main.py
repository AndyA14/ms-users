from fastapi import FastAPI
from app.rabbitmq import publish_event

app = FastAPI(title="MS Users")

@app.get("/health")
def health():
    return {"status": "ms-users running"}

@app.post("/users")
def create_user(user: dict):
    # Simulación de creación
    publish_event("user.created", user)
    return {"message": "User created", "data": user}
