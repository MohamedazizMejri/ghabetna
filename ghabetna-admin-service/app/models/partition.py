import uuid
from sqlalchemy import Column, String, ForeignKey, Float, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from geoalchemy2 import Geometry, Geography

from app.database import Base


class Partition(Base):

    __tablename__ = "partition"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    nom = Column(String(150), nullable=False)

    superficie = Column(Float)

    geom = Column(Geometry("POLYGON", srid=4326), nullable=False)

    location = Column(Geography("POINT", srid=4326))

    foret_id = Column(UUID(as_uuid=True), ForeignKey("foret.id"))

    agent_id = Column(UUID(as_uuid=True), ForeignKey("utilisateur.id"))

    created_at = Column(DateTime, server_default=func.now())

    foret = relationship("Foret", back_populates="partitions")