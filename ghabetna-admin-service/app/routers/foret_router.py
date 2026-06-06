'''from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.utils.deps import get_db

router = APIRouter(prefix="/forets", tags=["Forets"])


@router.get("/")
def get_forests(db: Session = Depends(get_db)):

    return db.execute("SELECT * FROM foret").fetchall()'''

from fastapi import APIRouter, Depends , HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.models.foret import Foret

from app.utils.deps import get_db
from app.schemas.foret_schema import ForetCreate, ForetResponse ,ForetUpdate ,MessageResponse
from app.services import foret_service
from sqlalchemy import func
import json

import json
from app.core.redis_client import get_redis

router = APIRouter(prefix="/forests", tags=["Forests"])


@router.post("/", response_model=ForetResponse)
def create_forest(forest: ForetCreate, db: Session = Depends(get_db)):

    return foret_service.create_forest(db, forest)


@router.get("/", response_model=list[ForetResponse])
def get_forests(db: Session = Depends(get_db)):

    return foret_service.get_forests(db)


@router.patch("/{forest_id}", response_model=ForetResponse)
def update_forest(forest_id: UUID, forest: ForetUpdate, db: Session = Depends(get_db)):

    updated_forest = foret_service.update_forest(db, str(forest_id), forest)

    if not updated_forest:
        raise HTTPException(status_code=404, detail="Forest not found")
    
    _publish_spatial_changed(forest_id)


    return updated_forest


@router.delete("/{forest_id}", response_model=MessageResponse)
def delete_forest(forest_id: UUID, db: Session = Depends(get_db)):

    deleted_forest = foret_service.delete_forest(db, str(forest_id))

    if not deleted_forest:
        raise HTTPException(status_code=404, detail="Forest not found")
    
    _publish_spatial_changed(None)

    return {"message": "Forest deleted"}

@router.put("/{forest_id}", response_model=ForetResponse)
def update_forest(
    forest_id: UUID,
    forest: ForetUpdate,
    db: Session = Depends(get_db)
):
    updated_forest = foret_service.update_forest(db, str(forest_id), forest)

    if not updated_forest:
        raise HTTPException(status_code=404, detail="Forest not found")

    return updated_forest



@router.put("/{forest_id}/assign-supervisor")
def assign_supervisor(
    forest_id: UUID,
    supervisor_id: UUID,
    db: Session = Depends(get_db)
):
    forest = db.query(Foret).filter(Foret.id == forest_id).first()

    if not forest:
        raise HTTPException(status_code=404, detail="Forest not found")

    # assign supervisor
    forest.supervised_by = supervisor_id
    db.commit()
    # Publish forest_assigned event
    try:
        r = get_redis()
        r.publish("forest_assigned", json.dumps({
            "supervisor_id": str(supervisor_id),
            "forest_id": str(forest_id),
            "forest_nom": forest.nom,
        }))
    except Exception as e:
        print(f"[Redis] publish failed: {e}")

    #  convert geom to GeoJSON
    result = db.query(
        Foret.id,
        Foret.nom,
        func.ST_AsGeoJSON(Foret.geom).label("geom"),
        Foret.created_by,
        Foret.supervised_by
    ).filter(Foret.id == forest.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "geom": json.loads(result.geom), 
        "created_by": result.created_by,
        "supervised_by": result.supervised_by
    }

"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.utils.deps import get_db
from app.schemas.foret_schema import ForetCreate, ForetUpdate, ForetResponse
from app.services.foret_service import forest_service

router = APIRouter(prefix="/forets", tags=["Forets"])


@router.post("/", response_model=ForetResponse)
def create_forest(forest: ForetCreate, db: Session = Depends(get_db)):
    return forest_service.create(db, forest.model_dump())


@router.get("/", response_model=list[ForetResponse])
def get_forests(db: Session = Depends(get_db)):
    return forest_service.get_all(db)


@router.patch("/{forest_id}", response_model=ForetResponse)
def update_forest(forest_id: UUID, forest: ForetUpdate, db: Session = Depends(get_db)):

    updated = forest_service.update(
        db,
        forest_id,
        forest.model_dump(exclude_unset=True)
    )

    if not updated:
        raise HTTPException(status_code=404, detail="Forest not found")

    return updated


@router.delete("/{forest_id}", response_model=ForetResponse)
def delete_forest(forest_id: UUID, db: Session = Depends(get_db)):

    deleted = forest_service.delete(db, forest_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Forest not found")

    return deleted
    """

def _publish_spatial_changed(foret_id):
    try:
        r = get_redis()
        r.publish("spatial_changed", json.dumps({"foret_id": str(foret_id) if foret_id else None}))
    except Exception as e:
        print(f"[Redis] spatial_changed publish failed: {e}")


@router.delete("/{forest_id}/unassign-supervisor", status_code=204)
def unassign_supervisor_route(
    forest_id: UUID,
    db: Session = Depends(get_db)
):
    forest = db.query(Foret).filter(Foret.id == forest_id).first()
    if not forest:
        raise HTTPException(status_code=404, detail="Forest not found")

    supervisor_id = str(forest.supervised_by) if forest.supervised_by else None
    forest.supervised_by = None
    db.commit()

    if supervisor_id:
        try:
            r = get_redis()
            r.publish("forest_unassigned", json.dumps({
                "supervisor_id": supervisor_id,
                "forest_id": str(forest_id),
            }))
        except Exception as e:
            print(f"[Redis] forest_unassigned publish failed: {e}")