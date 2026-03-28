from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.models.partition import Partition

from sqlalchemy import func
import json


from app.utils.deps import get_db
from app.schemas.partition_schema import (
    PartitionCreate,
    PartitionUpdate,
    PartitionResponse
)
from app.services.partition_service import (
    create_partition,
    get_partitions,
    update_partition,
    delete_partition,
)

router = APIRouter(prefix="/partitions", tags=["Partitions"])


@router.post("/", response_model=PartitionResponse)
def create_partition_route(partition: PartitionCreate, db: Session = Depends(get_db)):

    return create_partition(db, partition)



@router.get("/", response_model=list[PartitionResponse])
def get_partitions_route(db: Session = Depends(get_db)):

    return get_partitions(db)


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

    return updated



@router.delete("/{partition_id}", response_model=PartitionResponse)
def delete_partition_route(partition_id: UUID, db: Session = Depends(get_db)):

    deleted = delete_partition(db, partition_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Partition not found")

    return deleted



@router.put("/{partition_id}/assign-agent")
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
    }