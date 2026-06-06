from fastapi import APIRouter, Depends , HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from app.schemas.user_schema import UserUpdate



from app.utils.deps import get_db
from app.schemas.user_schema import UserCreate, UserResponse
from app.services import user_service

from app.core.redis_client import get_redis
import json

from app.models.utilisateur import Utilisateur as UtilisateurModel


router = APIRouter(prefix="/users", tags=["Users"])


@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    user = await user_service.create_user(db, user)
    return user


@router.get("/", response_model=list[UserResponse])
def get_users(db: Session = Depends(get_db)):

    return user_service.get_users(db)


@router.put("/{user_id}", response_model=UserResponse)
def update_user(user_id: UUID, user: UserCreate, db: Session = Depends(get_db)):
    updated_user = user_service.update_user(db, str(user_id), user)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user


@router.delete("/{user_id}", response_model=UserResponse)
def delete_user(user_id: UUID, db: Session = Depends(get_db)):
    deleted_user = user_service.delete_user(db, str(user_id))
    if not deleted_user:
        raise HTTPException(status_code=404, detail="User not found")
    return deleted_user


@router.patch("/{user_id}", response_model=UserResponse)
def update_user_partial_route(user_id: UUID, user: UserUpdate, db: Session = Depends(get_db)):
    updated_user = user_service.update_user_partial(db, str(user_id), user)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user

@router.get("/agents")
def get_agents(db: Session = Depends(get_db)):

    return user_service.get_agents(db)

@router.get("/superviseurs")
def get_supervisors(db: Session = Depends(get_db)):

    return user_service.get_supervisors(db)

# profile
@router.get("/{user_id}/cache-sync")
def sync_user_to_cache(user_id: str, db: Session = Depends(get_db)):
    """
    Force-push a user's data to Redis (useful on first login).
    Called by incident-service or Flutter when profile cache is empty.
    """
    from app.models.utilisateur import Utilisateur
    from app.models.partition import Partition
    from app.models.foret import Foret
    from sqlalchemy.orm import joinedload

    user = db.query(Utilisateur).options(
        joinedload(Utilisateur.role)
    ).filter(Utilisateur.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    r = get_redis()

    # Write profile
    r.setex(f"user:{user_id}:profile", 86400, json.dumps({
        "user_id": user_id,
        "nom": user.nom,
        "prenom": user.prenom,
        "email": user.email,
        "numtel": user.numtel,
        "cin": user.cin,
        "role": user.role.type_role if user.role else None,
    }))

    # Write parcelles (if agent)
    if user.role and user.role.type_role == "agent":
        """parcelles = db.query(Partition).filter(Partition.agent_id == user_id).all()
        parcelles_data = [{"partition_id": str(p.id), "partition_nom": p.nom} for p in parcelles]
        r.setex(f"user:{user_id}:parcelles", 86400, json.dumps(parcelles_data))"""
        # The agent object itself has partition_id
        parcelles_data = []
        if user.partition_id:
            partition = db.query(Partition).filter(Partition.id == user.partition_id).first()
            if partition:
                parcelles_data = [{"partition_id": str(partition.id), "partition_nom": partition.nom}]
        r.setex(f"user:{user_id}:parcelles", 86400, json.dumps(parcelles_data))

    # Write forests (if supervisor)
    if user.role and user.role.type_role == "superviseur":
        forests = db.query(Foret).filter(Foret.supervised_by == user_id).all()
        forests_data = [{"forest_id": str(f.id), "forest_nom": f.nom} for f in forests]
        r.setex(f"user:{user_id}:forests", 86400, json.dumps(forests_data))

    return {"message": "Cache populated"}