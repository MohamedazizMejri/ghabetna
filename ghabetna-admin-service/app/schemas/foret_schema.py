from pydantic import BaseModel
from uuid import UUID
from typing import Optional


class ForetCreate(BaseModel):

    nom: str
    geom: dict
    location: Optional[dict] = None
    created_by: UUID
    supervised_by: Optional[UUID] = None

class ForetUpdate(BaseModel):
    nom: Optional[str] = None
    geom: Optional[dict] = None
    location: Optional[dict] = None
    created_by: Optional[UUID] = None
    supervised_by: Optional[UUID] = None

class ForetResponse(BaseModel):

    id: UUID
    nom: str
    geom: dict
    location: Optional[dict]
    created_by: UUID
    supervised_by: Optional[UUID] = None

    class Config:
        from_attributes = True