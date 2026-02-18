from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from app.config import POSTGRES_URL

engine = create_engine(POSTGRES_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


# ── ORM Model ────────────────────────────────────────────────────────────────
class UserDB(Base):
    __tablename__ = "users"

    id    = Column(Integer, primary_key=True, index=True)
    name  = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    # Nunca guardes contraseñas en texto plano; aquí iría el hash.
    hashed_password = Column(String(255), nullable=False)


def init_db():
    """Crea las tablas si no existen. Llamar al arrancar la app."""
    Base.metadata.create_all(bind=engine)


# ── Dependency para FastAPI ───────────────────────────────────────────────────
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()