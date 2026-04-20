import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./data/aupp_lms.sqlite3")
SECRET_KEY = os.getenv("SECRET_KEY", "change-this-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
APP_ENV = os.getenv("APP_ENV", "dev").strip().lower()


def is_docs_enabled() -> bool:
    return APP_ENV in {"dev", "stage", "staging"}
