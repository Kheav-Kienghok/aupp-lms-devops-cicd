from sqlalchemy import select
from sqlalchemy.orm import Session

from core.security import verify_password
from models.user import User


def normalize_email(email: str) -> str:
    return email.lower().strip()


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(User.email == normalize_email(email)))


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = get_user_by_email(db, email)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user
