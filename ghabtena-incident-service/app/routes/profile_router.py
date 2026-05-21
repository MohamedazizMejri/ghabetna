"""
Profile endpoints for agent and supervisor interfaces.
Data is served from Redis cache (populated by admin-service events).
"""

from fastapi import APIRouter, HTTPException
from app.dependencies.auth import get_current_user
from fastapi import Depends
from app.core.redis_client import get_redis
import json

router = APIRouter(prefix="/profile", tags=["Profile"])


# 
@router.get("/me")
def get_my_profile(current_user: dict = Depends(get_current_user)):
    user_id = current_user["user_id"]
    r = get_redis()
    profile_raw = r.get(f"user:{user_id}:profile")
    if not profile_raw:
        raise HTTPException(
            status_code=404,
            detail="Profile not in cache. Try calling /users/{id}/cache-sync first."
        )
    return json.loads(profile_raw)


@router.get("/me/parcelles")
def get_my_parcelles(current_user: dict = Depends(get_current_user)):
    """
    Returns assigned forest parcels for the logged-in agent.
    Reads from Redis cache key: user:{user_id}:parcelles
    """
    if current_user["role"] != "agent":
        raise HTTPException(status_code=403, detail="Only agents have parcelles")

    user_id = current_user["user_id"]
    r = get_redis()

    parcelles_raw = r.get(f"user:{user_id}:parcelles")
    if not parcelles_raw:
        return []   # No parcelles assigned yet — return empty list

    return json.loads(parcelles_raw)


@router.get("/me/forests")
def get_my_forests(current_user: dict = Depends(get_current_user)):
    """
    Returns forests supervised by the logged-in supervisor.
    Reads from Redis cache key: user:{user_id}:forests
    """
    if current_user["role"] != "superviseur":
        raise HTTPException(status_code=403, detail="Only supervisors have forests")

    user_id = current_user["user_id"]
    r = get_redis()

    forests_raw = r.get(f"user:{user_id}:forests")
    if not forests_raw:
        return []

    return json.loads(forests_raw)


@router.patch("/me")
def update_my_profile(
    data: dict,
    current_user: dict = Depends(get_current_user)
):
    """
    Allows agent/supervisor to update editable fields in their profile cache.
    NOTE: Only updates the Redis cache locally. The admin-service DB is the
    source of truth; those fields will be overwritten on the next admin update.
    Editable fields: numtel only (phone number is safe to let the user change).
    """
    user_id = current_user["user_id"]
    r = get_redis()

    profile_raw = r.get(f"user:{user_id}:profile")
    if not profile_raw:
        raise HTTPException(status_code=404, detail="Profile not in cache")

    profile = json.loads(profile_raw)

    # Only allow safe self-editable fields
    EDITABLE_FIELDS = {"numtel"}
    for field, value in data.items():
        if field in EDITABLE_FIELDS:
            profile[field] = value

    r.setex(f"user:{user_id}:profile", 86400, json.dumps(profile))
    return profile