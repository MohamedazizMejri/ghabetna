from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from geoalchemy2 import Geography
import uuid

from app.database import Base

import enum


class IncidentStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class Incident(Base):
    __tablename__ = "incident"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    reference_code = Column(String, unique=True)
    description = Column(Text)
    image_url = Column(String)

    location = Column(Geography(geometry_type="POINT", srid=4326))

    status = Column(Enum(IncidentStatus), default=IncidentStatus.pending)
    comment = Column(Text)

    agent_id = Column(UUID(as_uuid=True), nullable=False)

    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime)
    reviewed_at = Column(DateTime)

    type_code = Column(String, ForeignKey("incident_type.code"), nullable=False)