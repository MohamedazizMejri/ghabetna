from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.models.partition import Partition

from sqlalchemy import func
import json

import json
from app.core.redis_client import get_redis

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from app.utils.deps import get_db


from app.utils.deps import get_db
from app.schemas.partition_schema import (
    PartitionCreate,
    PartitionUpdate,
    PartitionResponse,
    MessageResponse
)
from app.services.partition_service import (
    create_partition,
    get_partitions,
    update_partition,
    delete_partition,
    assign_agent,
    unassign_agent
)

import redis as redis_lib

router = APIRouter(prefix="/partitions", tags=["Partitions"])

def _publish_spatial_changed(foret_id):
    """Publish a spatial_changed event so the incident service invalidates caches."""

    try:
        r = get_redis()
        r.publish("spatial_changed", json.dumps({"foret_id": foret_id}))
    except Exception as e:
        print(f"[Redis] spatial_changed publish failed: {e}")

def _publish_partition_assigned(agent_id, partition_id, partition_nom):
    try:
        r = get_redis()
        r.publish("partition_assigned", json.dumps({
            "agent_id": str(agent_id),
            "partition_id": str(partition_id),
            "partition_nom": partition_nom,
        }))
    except Exception as e:
        print(f"[Redis] partition_assigned publish failed: {e}")

#---------------

@router.post("/", response_model=PartitionResponse)
def create_partition_route(partition: PartitionCreate, db: Session = Depends(get_db)):
    result = create_partition(db, partition)
    _publish_spatial_changed(str(result["foret_id"]))
    return result


@router.get("/", response_model=list[PartitionResponse])
def get_partitions_route(db: Session = Depends(get_db)):

    return get_partitions(db)

# which partition and which forest the incident is in 
@router.get("/lookup")
def lookup_partition_by_point(
    lat: float = Query(...),
    lng: float = Query(...),
    db: Session = Depends(get_db)
):
    """
    Returns the partition + forest containing this GPS point.
    If no partition covers it but a forest does, returns forest only.
    """
    # Step 1: try to find a partition that contains the point
    partition_result = db.execute(text("""
        SELECT p.id   AS parcelle_id,
               p.nom  AS parcelle_nom,
               f.id   AS foret_id,
               f.nom  AS foret_nom
        FROM   "partition" p
        JOIN   foret f ON f.id = p.foret_id
        WHERE  ST_Within(
                   ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
                   p.geom
               )
        LIMIT 1
    """), {"lat": lat, "lng": lng}).fetchone()

    if partition_result:
        return {
            "parcelle_id":  str(partition_result.parcelle_id),
            "parcelle_nom": partition_result.parcelle_nom,
            "foret_id":     str(partition_result.foret_id),
            "foret_nom":    partition_result.foret_nom,
        }

    # Step 2: no partition — try to find a forest that contains the point
    forest_result = db.execute(text("""
        SELECT id, nom
        FROM   foret
        WHERE  ST_Within(
                   ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
                   geom
               )
        LIMIT 1
    """), {"lat": lat, "lng": lng}).fetchone()

    if forest_result:
        return {
            "parcelle_id":  None,
            "parcelle_nom": None,
            "foret_id":     str(forest_result.id),
            "foret_nom":    forest_result.nom,
        }

    # Point is outside all known forest areas
    return {"parcelle_id": None, "parcelle_nom": None, "foret_id": None, "foret_nom": None}

"""@router.patch("/{partition_id}", response_model=PartitionResponse)
def update_partition(
    partition_id: UUID,
    partition: PartitionUpdate,
    db: Session = Depends(get_db)
):

    updated = partition_service.update(
        db,
        partition_id,
        partition.model_dump(exclude_unset=True)
    )

    if not updated:
        raise HTTPException(status_code=404, detail="Partition not found")

    return updated"""

@router.patch("/{partition_id}", response_model=PartitionResponse)
def update_partition_route(
    partition_id: UUID,
    partition: PartitionUpdate,
    db: Session = Depends(get_db)
):

    updated = update_partition(db, partition_id, partition)

    if not updated:
        raise HTTPException(status_code=404, detail="Partition not found")
    
    _publish_spatial_changed(str(updated["foret_id"]))

    return updated



@router.delete("/{partition_id}", response_model=MessageResponse)
def delete_partition_route(partition_id: UUID, db: Session = Depends(get_db)):

    deleted = delete_partition(db, partition_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Partition not found")
    
    _publish_spatial_changed(None)

    return {"message": "Forest deleted"}


# ── ASSIGN / UNASSIGN ─────────────────────────────────────────────────────────


"""@router.put("/{partition_id}/assign-agent")
def assign_agent(
    partition_id: UUID,
    agent_id: UUID,
    db: Session = Depends(get_db)
):
    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        raise HTTPException(status_code=404, detail="Partition not found")

    # assign agent
    partition.agent_id = agent_id
    db.commit()
    # Publish partition_assigned event
    try:
        r = get_redis()
        r.publish("partition_assigned", json.dumps({
            "agent_id": str(agent_id),
            "partition_id": str(partition_id),
            "partition_nom": partition.nom,
        }))
    except Exception as e:
        print(f"[Redis] publish failed: {e}")

    #  convert geom to GeoJSON
    result = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
        Partition.agent_id
    ).filter(Partition.id == partition.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "superficie": result.superficie,
        "geom": json.loads(result.geom),
        "foret_id": result.foret_id,
        "agent_id": result.agent_id
    }"""
@router.put("/{partition_id}/assign-agent", response_model=PartitionResponse)
def assign_agent_route(
    partition_id: UUID,
    agent_id: UUID,
    db: Session = Depends(get_db)
):
    result = assign_agent(db, partition_id, agent_id)
    _publish_partition_assigned(agent_id, partition_id, result["nom"])
    return result


@router.delete("/{partition_id}/unassign-agent/{agent_id}", status_code=204)
def unassign_agent_route(
    partition_id: UUID,
    agent_id: UUID,
    db: Session = Depends(get_db)
):
    unassign_agent(db, partition_id, agent_id)
    try:
        r = get_redis()
        r.publish("partition_unassigned", json.dumps({
            "agent_id": str(agent_id),
            "partition_id": str(partition_id),
        }))
    except Exception as e:
        print(f"[Redis] partition_unassigned publish failed: {e}")

