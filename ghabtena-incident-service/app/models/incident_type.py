from sqlalchemy import Column, String, Integer
from app.database import Base

class IncidentType(Base):
    __tablename__ = "incident_type"

    code = Column(String, primary_key=True, index=True)
    label = Column(String, nullable=False)
    severity = Column(Integer, default=1)