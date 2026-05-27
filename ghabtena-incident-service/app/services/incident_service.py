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

from app.models.incident_type import IncidentType


import json
from app.core.redis_client import get_redis

import requests
import os


DETAIL_CACHE_TTL = 3600  # 1 hour

ADMIN_SERVICE_URL = os.getenv("ADMIN_SERVICE_URL", "http://localhost:8000")


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
    r = get_redis()
    results = db.query(
        Incident.id,
        Incident.reference_code,
        Incident.description,
        Incident.status,
        Incident.image_url,
        Incident.type_code,
        IncidentType.severity,
        func.ST_Y(func.cast(Incident.location, Geometry)).label("latitude"),
        func.ST_X(func.cast(Incident.location, Geometry)).label("longitude"),
    ).join(
        IncidentType, Incident.type_code == IncidentType.code
    ).all()

    output = []
    for r_row in results:
        spatial = _lookup_spatial(r_row.latitude, r_row.longitude, r)
        output.append({
            "id": r_row.id,
            "reference_code": r_row.reference_code,
            "description": r_row.description,
            "status": r_row.status,
            "image_url": r_row.image_url,
            "type_code": r_row.type_code,
            "severity": r_row.severity,
            "latitude": r_row.latitude,
            "longitude": r_row.longitude,
            "foret_nom": spatial.get("foret_nom"),
            "parcelle_nom": spatial.get("parcelle_nom"),
        })
    return output

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
    get_redis().delete(f"incident:{incident_id}:details")
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


def get_incident_types(db):
    return db.query(IncidentType).all()

def get_incident_details(db: Session, incident_id) -> dict:
    cache_key = f"incident:{incident_id}:details"
    r = get_redis()

    # Cache hit → return immediately
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)

    # Load incident row with severity
    row = db.query(
        Incident.id, Incident.reference_code, Incident.description,
        Incident.type_code, Incident.status, Incident.comment,
        Incident.image_url, Incident.agent_id,
        Incident.created_at, Incident.reviewed_at,
        IncidentType.severity,
        func.ST_Y(func.cast(Incident.location, Geometry)).label("latitude"),
        func.ST_X(func.cast(Incident.location, Geometry)).label("longitude"),
    ).join(IncidentType, Incident.type_code == IncidentType.code
    ).filter(Incident.id == incident_id).first()

    if not row:
        raise HTTPException(status_code=404, detail="Incident not found")

    # Spatial lookup: which Parcelle contains this GPS point?
    spatial = {}
    if row.latitude is not None and row.longitude is not None:
        spatial = _lookup_spatial(row.latitude, row.longitude, r)


    detail = {
        "id": str(row.id),
        "reference_code": row.reference_code,
        "description": row.description,
        "type_code": row.type_code,
        "severity": row.severity,
        "status": row.status.value if hasattr(row.status, "value") else row.status,
        "comment": row.comment,
        "image_url": row.image_url,
        "latitude": row.latitude,
        "longitude": row.longitude,
        "agent_id": str(row.agent_id) if row.agent_id else None,
        "created_at": row.created_at.isoformat() if row.created_at else None,
        "reviewed_at": row.reviewed_at.isoformat() if row.reviewed_at else None,
        "foret_id":    spatial.get("foret_id"),
        "foret_nom":   spatial.get("foret_nom"),
        "parcelle_id":  spatial.get("parcelle_id"),
        "parcelle_nom": spatial.get("parcelle_nom"),
    }
    r.setex(cache_key, DETAIL_CACHE_TTL, json.dumps(detail))
    return detail

def _lookup_spatial(lat: float, lng: float, r) -> dict:
    """
    Ask admin-service which partition/forest contains this GPS point.
    Result is cached in Redis for 1 hour to avoid repeated HTTP calls.
    """
    cache_key = f"spatial:{round(lat,6)}:{round(lng,6)}"
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)

    try:
        resp = requests.get(
            f"{ADMIN_SERVICE_URL}/partitions/lookup",
            params={"lat": lat, "lng": lng},
            timeout=3
        )
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        print(f"[incident-service] spatial lookup failed: {e}")
        data = {"parcelle_id": None, "parcelle_nom": None, "foret_id": None, "foret_nom": None}

    r.setex(cache_key, 3600, json.dumps(data))
    return data