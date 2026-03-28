import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from geoalchemy2 import Geometry, Geography

from app.database import Base


class Foret(Base):

    __tablename__ = "foret"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    nom = Column(String(150), nullable=False)

    geom = Column(Geometry("POLYGON", srid=4326), nullable=False)

    location = Column(Geography("POINT", srid=4326))

    created_by = Column(UUID(as_uuid=True), ForeignKey("utilisateur.id"))

    supervised_by = Column(UUID(as_uuid=True), ForeignKey("utilisateur.id"))

    created_at = Column(DateTime, server_default=func.now())

    partitions = relationship("Partition", back_populates="foret")