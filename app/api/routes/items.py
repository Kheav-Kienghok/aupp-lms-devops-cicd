from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from api.deps import get_current_user
from core.metrics import track_request
from db.database import get_db
from models.item import Item
from models.user import User
from schemas.item import ItemCreate, ItemRead, ItemUpdate

router = APIRouter(tags=["items"])


@router.post("/items", response_model=ItemRead, status_code=status.HTTP_201_CREATED)
def create_item(
    item_in: ItemCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Item:
    track_request("POST", "/items")
    item = Item(
        title=item_in.title,
        description=item_in.description,
        owner_id=current_user.id,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/items", response_model=list[ItemRead])
def list_items(
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    skip: int = 0,
    limit: int = 20,
) -> list[Item]:
    track_request("GET", "/items")
    safe_limit = min(max(limit, 1), 100)
    safe_skip = max(skip, 0)
    items = db.scalars(
        select(Item)
        .where(Item.owner_id == current_user.id)
        .offset(safe_skip)
        .limit(safe_limit)
        .order_by(Item.id.desc())
    ).all()
    return items


@router.get("/items/{item_id}", response_model=ItemRead)
def get_item(
    item_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Item:
    track_request("GET", "/items/{item_id}")
    item = db.scalar(
        select(Item).where(Item.id == item_id, Item.owner_id == current_user.id)
    )
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )
    return item


@router.put("/items/{item_id}", response_model=ItemRead)
def update_item(
    item_id: int,
    item_in: ItemUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Item:
    track_request("PUT", "/items/{item_id}")
    item = db.scalar(
        select(Item).where(Item.id == item_id, Item.owner_id == current_user.id)
    )
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )

    if item_in.title is not None:
        cleaned_title = item_in.title.strip()
        if len(cleaned_title) < 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Title must be at least 3 characters",
            )
        item.title = cleaned_title.title()

    if item_in.description is not None:
        cleaned_description = item_in.description.strip()
        item.description = cleaned_description if cleaned_description else None

    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/items/{item_id}")
def delete_item(
    item_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict[str, str]:
    track_request("DELETE", "/items/{item_id}")
    item = db.scalar(
        select(Item).where(Item.id == item_id, Item.owner_id == current_user.id)
    )
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )

    db.delete(item)
    db.commit()
    return {"detail": "Item deleted"}
