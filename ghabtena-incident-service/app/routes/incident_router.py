from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.incident_schema import IncidentCreate
from app.services.incident_service import create_incident

from app.schemas.incident_schema import IncidentResponse

router = APIRouter()


@router.post("/incidents" ,response_model=IncidentResponse)
def create_incident_route(
    data: IncidentCreate,
    db: Session = Depends(get_db)
):
    incident = create_incident(db, data)

    return incident