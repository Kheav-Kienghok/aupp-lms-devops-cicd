from collections.abc import Generator
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from core.config import DATABASE_URL
from models.base import Base


def _ensure_sqlite_parent_dir(database_url: str) -> None:
    if not database_url.startswith("sqlite:///"):
        return

    sqlite_path = database_url.replace("sqlite:///", "", 1)
    if not sqlite_path or sqlite_path == ":memory:":
        return

    db_file = Path(sqlite_path)
    if not db_file.is_absolute():
        db_file = Path.cwd() / db_file

    db_file.parent.mkdir(parents=True, exist_ok=True)


_ensure_sqlite_parent_dir(DATABASE_URL)

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    # Import models so SQLAlchemy registers table metadata before create_all.
    import models.item  # noqa: F401
    import models.user  # noqa: F401

    Base.metadata.create_all(bind=engine)
