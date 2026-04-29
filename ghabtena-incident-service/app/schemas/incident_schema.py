from pydantic import BaseModel
from uuid import UUID

from typing import Optional
from enum import Enum

class IncidentCreate(BaseModel):
    description: str
    latitude: float
    longitude: float
    type_code: str
    image_url: str | None = None


class IncidentResponse(BaseModel):
    id: UUID
    reference_code: str
    description: str
    type_code: str

    class Config:
        from_attributes = True

class IncidentWithLocationResponse(IncidentResponse):
    latitude: float
    longitude: float

class IncidentStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class IncidentStatusUpdate(BaseModel):
    status: IncidentStatus
    comment: Optional[str] = None