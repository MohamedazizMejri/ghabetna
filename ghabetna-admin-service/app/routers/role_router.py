from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.utils.deps import get_db
from app.schemas.role_schema import RoleResponse
from app.services import role_service

router = APIRouter(prefix="/roles", tags=["Roles"])


@router.get("/", response_model=list[RoleResponse])
def get_roles(db: Session = Depends(get_db)):

    return role_service.get_roles(db)