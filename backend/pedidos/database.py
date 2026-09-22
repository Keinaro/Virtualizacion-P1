import os
from urllib.parse import quote_plus

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


def database_url() -> str:
    required = ("DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME")
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Faltan variables de entorno: {', '.join(missing)}")
    return (
        f"postgresql+psycopg2://{quote_plus(os.environ['DB_USER'])}:"
        f"{quote_plus(os.environ['DB_PASSWORD'])}@{os.environ['DB_HOST']}"
        f":{os.environ['DB_PORT']}/{os.environ['DB_NAME']}"
    )


engine = create_engine(database_url(), pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def crear_tablas() -> None:
    Base.metadata.create_all(bind=engine)
