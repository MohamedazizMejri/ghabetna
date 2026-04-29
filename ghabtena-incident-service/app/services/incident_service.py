from sqlalchemy.orm import Session
from geoalchemy2.shape import from_shape
from shapely.geometry import Point
import uuid

from app.models.incident import Incident

from sqlalchemy.orm import Session
from sqlalchemy import func


from geoalchemy2 import Geometry


from datetime import datetime
from fastapi import HTTPException


from app.schemas.incident_schema import IncidentStatusUpdate


def generate_reference():
    return f"REF-{uuid.uuid4().hex[:8]}"


def create_incident(db: Session, data,  agent_id:str):
    point = from_shape(Point(data.longitude, data.latitude), srid=4326)

    incident = Incident(
        reference_code=generate_reference(),
        description=data.description,
        image_url=data.image_url,
        location=point,
        type_code=data.type_code,
        agent_id=agent_id  # TODO: replace with JWT
    )

    db.add(incident)
    db.commit()
    db.refresh(incident)

    return incident



from sqlalchemy import func

def get_all_incidents(db: Session):
    results = db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.type_code,
        func.ST_Y(func.cast(Incident.location, Geometry)).label("latitude"),
        func.ST_X(func.cast(Incident.location, Geometry)).label("longitude"),
    ).all()

    return [
        {
            "id": r.id,
            "reference_code": r.reference_code,
            "description": r.description,
            "type_code": r.type_code,
            "latitude": r.latitude,
            "longitude": r.longitude,
        }
        for r in results
    ]

def update_incident_status(db: Session, incident_id, data: IncidentStatusUpdate , supervisor_id):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()

    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    #  Business rule
    if data.status == "rejected" and not data.comment:
        raise HTTPException(
            status_code=400,
            detail="Comment is required when rejecting an incident"
        )

    incident.status = data.status
    incident.comment = data.comment
    incident.reviewed_at = datetime.utcnow()

    incident.reviewed_by = supervisor_id

    # TODO later:
    # incident.reviewed_by = supervisor_id (from JWT)

    db.commit()
    db.refresh(incident)

    return incident

def get_incident_with_location(db: Session, incident_id):
    result = db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.type_code,
        func.ST_Y(Incident.location.cast(Geometry)).label("latitude"),
        func.ST_X(Incident.location.cast(Geometry)).label("longitude"),
    ).filter(Incident.id == incident_id).first()

    return result


def get_incident_by_id(db, incident_id):
    incident = db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.type_code,
        Incident.status,
        func.ST_Y(Incident.location.cast(Geometry)).label("latitude"),
        func.ST_X(Incident.location.cast(Geometry)).label("longitude"),
    ).filter(Incident.id == incident_id).first()

    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    return incident

def get_incidents_by_status(db, status: str):
    return db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.type_code,
        Incident.status,
        func.ST_Y(Incident.location.cast(Geometry)).label("latitude"),
        func.ST_X(Incident.location.cast(Geometry)).label("longitude"),
    ).filter(Incident.status == status).all()

def get_pending_incidents(db):
    return db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.type_code,
        Incident.status,
        func.ST_Y(Incident.location.cast(Geometry)).label("latitude"),
        func.ST_X(Incident.location.cast(Geometry)).label("longitude"),
    ).filter(Incident.status == "pending").all()

def get_agent_incidents(db, agent_id: str):
    return db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.type_code,
        Incident.status,
        func.ST_Y(Incident.location.cast(Geometry)).label("latitude"),
        func.ST_X(Incident.location.cast(Geometry)).label("longitude"),
    ).filter(Incident.agent_id == agent_id).all()