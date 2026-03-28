from pydantic import BaseModel
from uuid import UUID
from typing import Optional
from app.schemas.role_schema import RoleResponse


class UserCreate(BaseModel):

    nom: str
    prenom: str
    email: str
    numtel: str
    cin: str
    #password: str
    role_id: UUID




class UserResponse(BaseModel):

    id: UUID
    nom: str
    prenom: str
    email: str
    role: RoleResponse

    class Config:
        from_attributes = True 

class UserUpdate(BaseModel):
    nom: Optional[str]
    prenom: Optional[str]
    email: Optional[str]
    numtel: Optional[str]
    cin: Optional[str]
    #password: Optional[str]
    role_id: Optional[UUID]

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    id: UUID
    email: str
    role: str
    
    class Config:
        from_attributes = True

