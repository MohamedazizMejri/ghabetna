from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.utils.deps import get_db
from app.models.utilisateur import Utilisateur
from app.models.foret import Foret
from app.models.partition import Partition
from sqlalchemy.orm import joinedload
from app.models.role import Role


router = APIRouter(prefix="/stats", tags=["Stats"])

"""@router.get("/")
def get_stats(db: Session = Depends(get_db)):
    return {
        "admins": db.query(Utilisateur).filter(Utilisateur.role == "admin").count(),
        "supervisors": db.query(Utilisateur).filter(Utilisateur.role == "supervisor").count(),
        "agents": db.query(Utilisateur).filter(Utilisateur.role == "agent").count(),
        "forests": db.query(Foret).count(),
        "partitions": db.query(Partition).count(),
    }"""

@router.get("/")
def get_stats(db: Session = Depends(get_db)):
    admins = db.query(Utilisateur).join(Utilisateur.role).filter(Role.type_role == "admin").count()
    supervisors = db.query(Utilisateur).join(Utilisateur.role).filter(Role.type_role == "superviseur").count()
    agents = db.query(Utilisateur).join(Utilisateur.role).filter(Role.type_role == "agent").count()
    forests = db.query(Foret).count()
    partitions = db.query(Partition).count()

    return {
        "admins": admins,
        "supervisors": supervisors,
        "agents": agents,
        "forests": forests,
        "partitions": partitions
    }