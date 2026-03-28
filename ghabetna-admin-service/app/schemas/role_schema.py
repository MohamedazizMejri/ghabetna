from pydantic import BaseModel
from uuid import UUID


class RoleResponse(BaseModel):

    id: UUID
    type_role: str

    class Config:
        from_attributes = True