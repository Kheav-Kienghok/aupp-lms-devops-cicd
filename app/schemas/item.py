from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ItemCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=500)

    @field_validator("title")
    @classmethod
    def clean_title(cls, value: str) -> str:
        return value.strip()

    @field_validator("description")
    @classmethod
    def clean_description(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        return cleaned if cleaned else None


class ItemUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=500)


class ItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str | None
    owner_id: int
    created_at: datetime
    updated_at: datetime
