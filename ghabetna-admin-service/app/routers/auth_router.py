from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.utils.deps import get_db
from app.models.utilisateur import Utilisateur
from app.schemas.user_schema import UserResponse,UserLogin,LoginResponse
from passlib.hash import bcrypt
from app.schemas.auth_schema import ChangePasswordRequest
import bcrypt

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

from app.core.security import create_access_token
from app.core.security import verify_password
@router.post("/login",response_model=LoginResponse)
def login(data: UserLogin, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(
        Utilisateur.email == data.email
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="Wrong password")

    token = create_access_token({
        "sub": str(user.id),
        "role": user.role.type_role
    })

    return {
        "access_token": token,
        "role": user.role.type_role,
        "id": str(user.id),
    }
"""@router.post("/set-password")
def set_password(data: SetPasswordRequest, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(Utilisateur.reset_token == data.token).first()

    if not user:
        raise HTTPException(status_code=400, detail="Invalid token")

    print("Password received:", data.password)
    print("Bytes length:", len(data.password.encode("utf-8")))

    # Hash password using bcrypt 5.x
    password_bytes = data.password.encode("utf-8")       # convert to bytes
    hashed = bcrypt.hashpw(password_bytes, bcrypt.gensalt())  # hash
    hashed_str = hashed.decode("utf-8")                  # decode to string for DB

    # Save hashed password
    user.password = hashed_str
    user.reset_token = None
    

    db.commit()

    return {"message": "Password set successfully"}"""

"""@router.post("/change-password")
def change_password(data: ChangePasswordRequest, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(Utilisateur.id == data.user_id).first()

    if not bcrypt.verify(data.old_password, user.password):
        raise HTTPException(status_code=401, detail="Wrong password")

    user.password = bcrypt.hash(data.new_password)
    db.commit()

    return {"message": "Password updated"}"""