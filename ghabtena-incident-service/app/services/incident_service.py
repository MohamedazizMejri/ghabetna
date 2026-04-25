from sqlalchemy.orm import Session
from geoalchemy2.shape import from_shape
from shapely.geometry import Point
import uuid

from app.models.incident import Incident


def generate_reference():
    return f"REF-{uuid.uuid4().hex[:8]}"


def create_incident(db: Session, data):
    point = from_shape(Point(data.longitude, data.latitude), srid=4326)

    incident = Incident(
        reference_code=generate_reference(),
        description=data.description,
        image_url=data.image_url,
        location=point,
        type_code=data.type_code,
        agent_id=uuid.uuid4()  # TODO: replace with JWT
    )

    db.add(incident)
    db.commit()
    db.refresh(incident)

    return incident