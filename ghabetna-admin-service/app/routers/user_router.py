from fastapi import APIRouter, Depends , HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from app.schemas.user_schema import UserUpdate



from app.utils.deps import get_db
from app.schemas.user_schema import UserCreate, UserResponse
from app.services import user_service

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