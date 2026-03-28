import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base

class Utilisateur(Base):
    __tablename__ = "utilisateur"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    nom = Column(String(100), nullable=False)
    prenom = Column(String(100), nullable=False)

    email = Column(String(150), unique=True, nullable=False)
    numtel = Column(String(20))
    cin = Column(String(20), unique=True)

    password = Column(String, nullable=False)



    role_id = Column(UUID(as_uuid=True), ForeignKey("role.id"))

    created_at = Column(DateTime, server_default=func.now())

    role = relationship("Role", back_populates="utilisateurs")