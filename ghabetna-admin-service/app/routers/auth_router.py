from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.utils.deps import get_db
from app.models.utilisateur import Utilisateur
from app.schemas.user_schema import UserResponse,UserLogin,LoginResponse

router = APIRouter(prefix="/auth", tags=["Auth"])

"""@router.post("/login")
def login(email: str, password: str, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(
        Utilisateur.email == email
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    
    if user.password != password:
        raise HTTPException(status_code=401, detail="Wrong password")
    
                    if not pwd_context.verify(password, user.password):
                    raise HTTPException(status_code=401, detail="Wrong password")

    return {
        "id": str(user.id),
        "email": user.email,
        "role": user.role.type_role
    }"""

@router.post("/login", response_model=LoginResponse)
def login(data: UserLogin, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(
        Utilisateur.email == data.email
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.password != data.password:
        raise HTTPException(status_code=401, detail="Wrong password")

    return {
        "id": user.id,
        "email": user.email,
        "role": user.role.type_role
    }