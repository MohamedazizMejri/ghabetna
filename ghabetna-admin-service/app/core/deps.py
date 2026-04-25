from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer
from jose import jwt, JWTError
from app.core.security import SECRET_KEY, ALGORITHM
from fastapi import HTTPException
security = HTTPBearer()


def get_current_user(token=Depends(security)):
    try:
        payload = jwt.decode(token.credentials, SECRET_KEY, algorithms=[ALGORITHM])

        user_id = payload.get("sub")
        role = payload.get("role")

        return {
            "user_id": user_id,
            "role": role
        }

    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    


def require_admin(user):
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin only")


def require_supervisor(user):
    if user["role"] not in ["admin", "superviseur"]:
        raise HTTPException(status_code=403, detail="Supervisor only")


def require_agent(user):
    if user["role"] not in ["admin", "superviseur", "agent"]:
        raise HTTPException(status_code=403, detail="Agent only")