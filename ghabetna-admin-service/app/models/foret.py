import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime, Float, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from geoalchemy2 import Geometry, Geography

from app.database import Base
import enum


class Gouvernorat(str, enum.Enum):
    ARIANA = "Ariana"
    BEJA = "Béja"
    BEN_AROUS = "Ben Arous"
    BIZERTE = "Bizerte"
    GABES = "Gabès"
    GAFSA = "Gafsa"
    JENDOUBA = "Jendouba"
    KAIROUAN = "Kairouan"
    KASSERINE = "Kasserine"
    KEBILI = "Kébili"
    LE_KEF = "Le Kef"
    MAHDIA = "Mahdia"
    MANOUBA = "La Manouba"
    MEDENINE = "Médenine"
    MONASTIR = "Monastir"
    NABEUL = "Nabeul"
    SFAX = "Sfax"
    SIDI_BOUZID = "Sidi Bouzid"
    SILIANA = "Siliana"
    SOUSSE = "Sousse"
    TATAOUINE = "Tataouine"
    TOZEUR = "Tozeur"
    TUNIS = "Tunis"
    ZAGHOUAN = "Zaghouan"

class Foret(Base):

    __tablename__ = "foret"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    nom = Column(String(150), nullable=False)

    geom = Column(Geometry("POLYGON", srid=4326), nullable=False)

    location = Column(Geography("POINT", srid=4326))

    superficie_km2 = Column(Float, nullable=True)
 
    region = Column(
    Enum(
        Gouvernorat,
        values_callable=lambda obj: [e.value for e in obj]
    ),
    nullable=True
)
    created_by = Column(UUID(as_uuid=True), ForeignKey("utilisateur.id"))

    supervised_by = Column(UUID(as_uuid=True), ForeignKey("utilisateur.id"))

    created_at = Column(DateTime, server_default=func.now())

    partitions = relationship("Partition", back_populates="foret")