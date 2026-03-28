from pydantic import BaseModel
from uuid import UUID
from typing import Optional


class PartitionCreate(BaseModel):

    nom: str
    superficie: float
    geom: dict
    foret_id: UUID
    agent_id: Optional[UUID] = None

class PartitionResponse(BaseModel):

    id: UUID
    nom: str
    superficie: float
    geom: dict
    foret_id: UUID
    agent_id: Optional[UUID] = None

    class Config:
        from_attributes = True

class PartitionUpdate(BaseModel):
    nom: Optional[str] = None
    superficie: Optional[float] = None
    geom: Optional[dict] = None
    foret_id: Optional[UUID] = None
    agent_id: Optional[UUID] = None
