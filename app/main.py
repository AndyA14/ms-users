from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from hashlib import sha256

from app.database import get_db, init_db, UserDB
from app.models import UserCreate, UserResponse
from app.rabbitmq import publish_event

app = FastAPI(title="MS Users")


@app.on_event("startup")
def on_startup():
    """Crea tablas en PostgreSQL al arrancar."""
    init_db()
    print("✅ PostgreSQL tables ready.")


# ── Health ─────────────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ms-users running"}


# ── Crear usuario ──────────────────────────────────────────────────────────────
@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate, db: Session = Depends(get_db)):

    # 1. Validar que el email no exista
    existing = db.query(UserDB).filter(UserDB.email == user.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    # 2. Guardar en PostgreSQL
    # ⚠️  En producción usa bcrypt, no sha256.
    hashed = sha256(user.password.encode()).hexdigest()
    db_user = UserDB(name=user.name, email=user.email, hashed_password=hashed)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # 3. Publicar evento a RabbitMQ (también queda logueado en MongoDB)
    publish_event("user.created", {"id": db_user.id, "email": db_user.email})

    return db_user


# ── Obtener usuario ────────────────────────────────────────────────────────────
@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user