from sqlalchemy.orm import Session
from app.models.utilisateur import Utilisateur
from app.schemas.user_schema import UserCreate
from app.schemas.user_schema import UserUpdate
from app.models.role import Role
from sqlalchemy.orm import joinedload


def create_user(db: Session, user: UserCreate):

    new_user = Utilisateur(
        nom=user.nom,
        prenom=user.prenom,
        email=user.email,
        numtel=user.numtel,
        cin=user.cin,
        password=None,
        role_id=user.role_id
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


def get_users(db: Session):

    return db.query(Utilisateur).options(joinedload(Utilisateur.role)).all()

def update_user(db: Session, user_id: str, updated_user: UserCreate):
    user = db.query(Utilisateur).filter(Utilisateur.id == user_id).first()
    if not user:
        return None
    user.nom = updated_user.nom
    user.prenom = updated_user.prenom
    user.email = updated_user.email
    user.numtel = updated_user.numtel
    user.cin = updated_user.cin
    #user.password =updated_user.password,# DO NOT update password at all
    user.role_id = updated_user.role_id

    db.commit()
    db.refresh(user)
    return user

def delete_user(db: Session, user_id: str):
    user = db.query(Utilisateur).filter(Utilisateur.id == user_id).first()
    if not user:
        return None
    db.delete(user)
    db.commit()
    return user

from app.schemas.user_schema import UserUpdate

def update_user_partial(db: Session, user_id: str, user_update: UserUpdate):
    user = db.query(Utilisateur).filter(Utilisateur.id == user_id).first()
    if not user:
        return None

    for field, value in user_update.model_dump(exclude_unset=True).items():
        setattr(user, field, value)

    db.commit()
    db.refresh(user)
    return user

def get_agents(db: Session):

    return db.query(Utilisateur).join(Role).filter(Role.type_role == "agent").all()

def get_supervisors(db: Session):

    return (
        db.query(Utilisateur)
        .join(Role)
        .filter(Role.type_role == "superviseur")
        .all()
    )