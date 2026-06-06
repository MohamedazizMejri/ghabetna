from pydantic import BaseModel
from uuid import UUID
from typing import Optional
from app.models.foret import Gouvernorat


class ForetCreate(BaseModel):

    nom: str
    geom: dict
    location: Optional[dict] = None
    region: Optional[Gouvernorat] = None
    created_by: UUID
    supervised_by: Optional[UUID] = None

class ForetUpdate(BaseModel):
    nom: Optional[str] = None
    geom: Optional[dict] = None
    location: Optional[dict] = None
    region: Optional[Gouvernorat] = None
    created_by: Optional[UUID] = None
    supervised_by: Optional[UUID] = None

class ForetResponse(BaseModel):

    id: UUID
    nom: str
    geom: dict
    location: Optional[dict]
    superficie_km2: Optional[float] = None
    region: Optional[Gouvernorat] = None
    created_by: UUID
    supervised_by: Optional[UUID] = None

    class Config:
        from_attributes = True

class MessageResponse(BaseModel):
    message: str