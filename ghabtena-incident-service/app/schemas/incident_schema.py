from pydantic import BaseModel
from uuid import UUID

from typing import Optional
from enum import Enum

from datetime import datetime


class IncidentCreate(BaseModel):
    description: str
    latitude: float
    longitude: float
    type_code: str
    image_url: str | None = None
    severity: bool = False


class IncidentResponse(BaseModel):
    id: UUID
    reference_code: str
    description: str
    type_code: str

    class Config:
        from_attributes = True

"""class IncidentWithLocationResponse(IncidentResponse):
    latitude: float
    longitude: float"""
class IncidentWithLocationResponse(BaseModel):
    id: UUID
    reference_code: str
    description: str
    status: Optional[str] = None
    image_url: Optional[str] = None
    type_code: str
    # Per-incident boolean: True = critical (agent toggled on), False = not critical
    severity: bool
    latitude: float
    longitude: float
    foret_id: Optional[str] = None
    foret_nom: Optional[str] = None      # 
    parcelle_nom: Optional[str] = None   # 

    class Config:
        from_attributes = True

class IncidentStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class IncidentStatusUpdate(BaseModel):
    status: IncidentStatus
    comment: Optional[str] = None

#you can delete this later IncidentDetailResponse

class IncidentDetailResponse(BaseModel):

    id: UUID
    reference_code: str
    description: str
    type_code: str
    # Per-incident boolean critical flag
    severity: bool
    status: Optional[str] = None
    comment: Optional[str] = None
    image_url: Optional[str] = None
    latitude: float
    longitude: float
    agent_id: Optional[UUID] = None
    agent_nom: Optional[str] = None       # ← from agent's Redis profile
    agent_prenom: Optional[str] = None    # ← from agent's Redis profile
    created_at: Optional[str] = None
    reviewed_at: Optional[str] = None

    # 
    foret_id: Optional[UUID] = None
    foret_nom: Optional[str] = None
    parcelle_id: Optional[UUID] = None
    parcelle_nom: Optional[str] = None

    class Config:
        from_attributes = True


class AgentIncidentResponse(BaseModel):
    id: UUID
    reference_code: str
    description: str
    type_code: str
    status: Optional[str] = None
    created_at: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        from_attributes = True