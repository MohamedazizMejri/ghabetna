from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.incident_schema import IncidentCreate
from app.services.incident_service import create_incident

from app.schemas.incident_schema import IncidentResponse


from typing import List , Optional
from app.services.incident_service import get_all_incidents
from app.schemas.incident_schema import IncidentResponse
from app.schemas.incident_schema import IncidentWithLocationResponse

from app.dependencies.auth import get_current_user
from fastapi import HTTPException

from app.models.incident import Incident
from sqlalchemy import func
from geoalchemy2 import Geometry
from app.services.incident_service import get_incident_with_location

from app.services.incident_service import get_incident_by_id
from app.services.incident_service import get_incidents_by_status
from app.services.incident_service import get_pending_incidents
from app.services.incident_service import get_agent_incidents

from fastapi import UploadFile, File, Form
import uuid
import os

from app.models.incident_type import IncidentType

from app.services.incident_service import get_incident_types


from app.schemas.incident_schema import IncidentDetailResponse
from app.services.incident_service import get_incident_details

from app.schemas.incident_schema import AgentIncidentResponse  



router = APIRouter()


"""@router.post("/incidents" ,response_model=IncidentResponse)
def create_incident_route(
    data: IncidentCreate,
    db: Session = Depends(get_db)
):
    incident = create_incident(db, data)

    return incident"""


"""@router.post("/incidents",response_model=IncidentResponse)
def create_incident_route(
    data: IncidentCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    print("CURRENT USER:", current_user)
    if current_user["role"] != "agent":
        raise HTTPException(status_code=403, detail="Only agents can create incidents")

    incident = create_incident(
        db,
        data,
        agent_id=current_user["user_id"]
    )

    return incident"""

@router.post("/incidents", response_model=IncidentResponse)
def create_incident_route(
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    type_code: str = Form(...),
    image: UploadFile = File(...),  
    # "true" when the agent toggled Critical ON, absent or "false" otherwise
    severity: Optional[str] = Form(default=None), 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    print("CURRENT USER:", current_user)

    if current_user["role"] != "agent":
        raise HTTPException(status_code=403, detail="Only agents can create incidents")

    #  Generate unique filename
    filename = f"{uuid.uuid4()}_{image.filename}"
    file_path = os.path.join("uploads", filename)

    #  Save file
    with open(file_path, "wb") as buffer:
        buffer.write(image.file.read())

    # Convert the form string to a proper boolean
    is_critical = severity is not None and severity.strip().lower() == "true"

    #  Build data (same structure as before)
    class Data:
        pass

    data = Data()
    data.description = description
    data.latitude = latitude
    data.longitude = longitude
    data.type_code = type_code
    data.image_url = f"/uploads/{filename}"

    incident = create_incident(
        db,
        data,
        agent_id=current_user["user_id"] ,
        severity=is_critical,
    )

    return incident



"""@router.get("/incidents", response_model=List[IncidentWithLocationResponse])
def get_incidents_route(db: Session = Depends(get_db)):
    incidents = get_all_incidents(db)
    return incidents"""

from uuid import UUID
from app.schemas.incident_schema import IncidentStatusUpdate
from app.services.incident_service import update_incident_status


"""@router.patch("/incidents/{incident_id}/status")
def update_status_route(
    incident_id: UUID,
    data: IncidentStatusUpdate,
    db: Session = Depends(get_db)
):
    incident = update_incident_status(db, incident_id, data)

    return {
        "id": incident.id,
        "status": incident.status,
        "comment": incident.comment,
        "reviewed_at": incident.reviewed_at
    }"""
@router.patch("/incidents/{incident_id}/status")
def update_status_route(
    incident_id: UUID,
    data: IncidentStatusUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "superviseur":
        raise HTTPException(status_code=403, detail="Only supervisors allowed")

    incident = update_incident_status(
        db,
        incident_id,
        data,
        supervisor_id=current_user["user_id"]
    )
    result = get_incident_with_location(db, incident_id)

    return {
        "id": result.id,
        "reference_code": result.reference_code,
        "description": result.description,
        "type_code": result.type_code,
        "latitude": result.latitude,
        "longitude": result.longitude,
    }

#you can delete this later incident details
@router.get("/incidents/{incident_id}/details",
            response_model=IncidentDetailResponse)
def get_incident_details_route(
    incident_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] != "superviseur":
        raise HTTPException(
            status_code=403,
            detail="Only supervisors can view incident details"
        )
    return get_incident_details(db, incident_id)


@router.get("/incidents/my",response_model=list[AgentIncidentResponse])
def get_my_incidents_route(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    #return get_agent_incidents(db, current_user["user_id"])
    rows = get_agent_incidents(db, current_user["user_id"])
    return [
        {
            "id": r.id,
            "reference_code": r.reference_code,
            "description": r.description,
            "type_code": r.type_code,
            "status": r.status.value if r.status else None,
            "created_at": r.created_at.isoformat() if r.created_at else None,  
            "latitude": r.latitude,
            "longitude": r.longitude,
        }
        for r in rows
    ]

@router.get("/incidents/{incident_id}")
def get_incident_route(
    incident_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    return get_incident_by_id(db, incident_id)

@router.get("/incidents",response_model=List[IncidentWithLocationResponse])
def get_incidents_route(
    status: str | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):

    if status:
        return get_incidents_by_status(db, status)

    return get_all_incidents(db)

@router.get("/incidents/pending")
def get_pending_route(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "superviseur":
        raise HTTPException(status_code=403, detail="Only supervisors allowed")

    return get_pending_incidents(db)



@router.get("/incident-types")
def get_types(db: Session = Depends(get_db)):
    types = get_incident_types(db)

    return [
        {
            "code": t.code,
            "label": t.label,
            "severity": t.severity
        }
        for t in types
    ]