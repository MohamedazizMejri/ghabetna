from pydantic import BaseModel
from uuid import UUID
from typing import Optional


class AgentInPartition(BaseModel):
    id: UUID
    nom: str
    prenom: str
    email: str

    class Config:
        from_attributes = True


class PartitionCreate(BaseModel):

    nom: str
    superficie: float
    geom: dict
    foret_id: UUID
    #agent_id: Optional[UUID] = None

class PartitionResponse(BaseModel):

    id: UUID
    nom: str
    superficie: Optional[float] = None   
    geom: dict
    foret_id: UUID
    #agent_id: Optional[UUID] = None
    agents: list[AgentInPartition] = []  # replaces agent_id

    class Config:
        from_attributes = True

class PartitionUpdate(BaseModel):
    nom: Optional[str] = None
    #superficie: Optional[float] = None
    geom: Optional[dict] = None
    foret_id: Optional[UUID] = None
    #agent_id: Optional[UUID] = None

class MessageResponse(BaseModel):
    message: str