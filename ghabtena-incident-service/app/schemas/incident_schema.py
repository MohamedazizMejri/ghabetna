from pydantic import BaseModel
from uuid import UUID


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