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

@router.post("/login", response_model=LoginResponse)
def login(data: UserLogin, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(
        Utilisateur.email == data.email
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify password using bcrypt
    input_password_bytes = data.password.encode("utf-8")       # convert input password to bytes
    """hashed_password_bytes = user.password.encode("utf-8") """     # convert stored hash to bytes

    """if user.password != data.password:
        raise HTTPException(status_code=401, detail="Wrong password")"""
    """if not bcrypt.checkpw(input_password_bytes, hashed_password_bytes):
        raise HTTPException(status_code=401, detail="Wrong password")"""
    try:
        # Try bcrypt check first (new users)
        hashed_password_bytes = user.password.encode("utf-8")
        if not bcrypt.checkpw(input_password_bytes, hashed_password_bytes):
            raise HTTPException(status_code=401, detail="Wrong password")
    except ValueError:
        # If ValueError: invalid salt, the password is likely plain text (old users)
        if user.password != data.password:
            raise HTTPException(status_code=401, detail="Wrong password")
        # Optional: migrate old password to bcrypt
        user.password = bcrypt.hashpw(input_password_bytes, bcrypt.gensalt()).decode("utf-8")

    return {
        "id": user.id,
        "email": user.email,
        "role": user.role.type_role
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

@router.post("/change-password")
def change_password(data: ChangePasswordRequest, db: Session = Depends(get_db)):

    user = db.query(Utilisateur).filter(Utilisateur.id == data.user_id).first()

    if not bcrypt.verify(data.old_password, user.password):
        raise HTTPException(status_code=401, detail="Wrong password")

    user.password = bcrypt.hash(data.new_password)
    db.commit()

    return {"message": "Password updated"}