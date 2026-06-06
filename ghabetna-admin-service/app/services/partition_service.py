"""from app.models.partition import Partition
from app.services.base_service import BaseService

partition_service = BaseService(Partition)"""

from sqlalchemy.orm import Session
from sqlalchemy import func
import json
from uuid import UUID
from app.models.foret import Foret
from fastapi import HTTPException

from app.models.partition import Partition
from app.schemas.partition_schema import PartitionCreate, PartitionUpdate


"""def create_partition(db: Session, partition: PartitionCreate):

    new_partition = Partition(
        nom=partition.nom,
        superficie=partition.superficie,
        geom=func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(partition.geom)), 4326
        ),
        foret_id=partition.foret_id,
        agent_id=partition.agent_id
    )

    db.add(new_partition)
    db.commit()
    db.refresh(new_partition)

    return new_partition"""
"""def create_partition(db: Session, partition: PartitionCreate):

    # Convert GeoJSON → PostGIS geometry
    partition_geom = func.ST_SetSRID(
        func.ST_GeomFromGeoJSON(json.dumps(partition.geom)), 4326
    )

    # Get forest geometry
    forest_geom = db.query(Foret.geom).filter(
        Foret.id == partition.foret_id
    ).scalar()

    if not forest_geom:
        raise HTTPException(
            status_code=404,
            detail="Forest not found"
        )

    # Check if partition is inside the forest
    is_within = db.query(
        func.ST_Within(partition_geom, forest_geom)
    ).scalar()

    if not is_within:
        raise HTTPException(
            status_code=400,
            detail="Partition must be inside the forest"
        )

    # Create partition if valid
    new_partition = Partition(
        nom=partition.nom,
        superficie=partition.superficie,
        geom=partition_geom,
        foret_id=partition.foret_id,
        agent_id=partition.agent_id
    )

    db.add(new_partition)
    db.commit()
    db.refresh(new_partition)

    return new_partition


def get_partitions(db: Session):

    partitions = (
        db.query(
            Partition.id,
            Partition.nom,
            Partition.superficie,
            func.ST_AsGeoJSON(Partition.geom).label("geom"),
            Partition.foret_id,
            Partition.agent_id
        )
        .all()
    )

    return partitions


def update_partition(db: Session, partition_id: UUID, partition_update: PartitionUpdate):

    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        return None

    update_data = partition_update.model_dump(exclude_unset=True)

    if "geom" in update_data:
        partition.geom = func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(update_data["geom"])), 4326
        )
        del update_data["geom"]

    for field, value in update_data.items():
        setattr(partition, field, value)

    db.commit()
    db.refresh(partition)

    return partition


def delete_partition(db: Session, partition_id: UUID):

    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        return None

    db.delete(partition)
    db.commit()

    return partition"""

import json
from sqlalchemy import func
from fastapi import HTTPException

"""def create_partition(db: Session, partition: PartitionCreate):

    partition_geom = func.ST_SetSRID(
        func.ST_GeomFromGeoJSON(json.dumps(partition.geom)), 4326
    )

    forest_geom = db.query(Foret.geom).filter(
        Foret.id == partition.foret_id
    ).scalar()

    if not forest_geom:
        raise HTTPException(status_code=404, detail="Forest not found")

    is_within = db.query(
        func.ST_Within(partition_geom, forest_geom)
    ).scalar()

    if not is_within:
        raise HTTPException(
            status_code=400,
            detail="Partition must be inside the forest"
        )

    new_partition = Partition(
        nom=partition.nom,
        superficie=partition.superficie,
        geom=partition_geom,
        foret_id=partition.foret_id,
        agent_id=partition.agent_id
    )

    db.add(new_partition)
    db.commit()
    db.refresh(new_partition)

    # Convert to GeoJSON
    result = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
        Partition.agent_id
    ).filter(Partition.id == new_partition.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "superficie": result.superficie,
        "geom": json.loads(result.geom),  
        "foret_id": result.foret_id,
        "agent_id": result.agent_id
    }

def get_partitions(db: Session):

    partitions = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
        Partition.agent_id
    ).all()

    result = []

    for p in partitions:
        result.append({
            "id": p.id,
            "nom": p.nom,
            "superficie": p.superficie,
            "geom": json.loads(p.geom),  
            "foret_id": p.foret_id,
            "agent_id": p.agent_id
        })

    return result

def update_partition(db: Session, partition_id: UUID, partition_update: PartitionUpdate):

    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        return None

    update_data = partition_update.model_dump(exclude_unset=True)

    if "geom" in update_data:
        partition.geom = func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(update_data["geom"])), 4326
        )
        del update_data["geom"]

    for field, value in update_data.items():
        setattr(partition, field, value)

    db.commit()
    db.refresh(partition)

    #  Convert to GeoJSON
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

def delete_partition(db: Session, partition_id: UUID):

    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        return None

    db.delete(partition)
    db.commit()

    return {"message": "Partition deleted"}"""

import json
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException

from app.models.partition import Partition
from app.models.foret import Foret
from app.models.utilisateur import Utilisateur
from app.schemas.partition_schema import PartitionCreate, PartitionUpdate

def _compute_km2(db: Session, geom_json: dict) -> float:
    """Calculate area in km² using PostGIS ST_Area on geography cast."""
    result = db.execute(
        func.ST_Area(
            func.ST_GeogFromWKB(
                func.ST_AsEWKB(
                    func.ST_SetSRID(
                        func.ST_GeomFromGeoJSON(json.dumps(geom_json)), 4326
                    )
                )
            )
        )
    ).scalar()
    return round(result / 1_000_000, 6) if result else 0.0
 
 
def _partition_to_dict(db: Session, partition_id) -> dict:
    """Fetch a partition and include its agents list."""
    row = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
    ).filter(Partition.id == partition_id).first()

    if not row:
        return None

    agents = db.query(Utilisateur).filter(
        Utilisateur.partition_id == partition_id
    ).all()

    return {
        "id": row.id,
        "nom": row.nom,
        "superficie": row.superficie,
        "geom": json.loads(row.geom),
        "foret_id": row.foret_id,
        "agents": [
            {"id": a.id, "nom": a.nom, "prenom": a.prenom, "email": a.email}
            for a in agents
        ],
    }



#  CREATE PARTITION
def create_partition(db: Session, partition: PartitionCreate):

    #  Safety check
    if not partition.geom:
        raise HTTPException(status_code=400, detail="Geometry is required")

    # Convert GeoJSON → PostGIS
    partition_geom = func.ST_SetSRID(
        func.ST_GeomFromGeoJSON(json.dumps(partition.geom)), 4326
    )

    #  Use scalar_subquery (FIX)
    forest_subquery = db.query(Foret.geom).filter(
        Foret.id == partition.foret_id
    ).scalar_subquery()

    # Check if forest exists
    forest_exists = db.query(Foret.id).filter(
        Foret.id == partition.foret_id
    ).first()

    if not forest_exists:
        raise HTTPException(status_code=404, detail="Forest not found")

    # Spatial validation
    is_within = db.query(
        func.ST_Within(partition_geom, forest_subquery)
    ).scalar()

    if not is_within:
        raise HTTPException(
            status_code=400,
            detail="Partition must be inside the forest"
        )
    # Auto-calculate superficie in km²
    superficie_km2 = _compute_km2(db, partition.geom)
    # Create partition
    new_partition = Partition(
        nom=partition.nom,
        superficie=superficie_km2,
        geom=partition_geom,
        foret_id=partition.foret_id,
        #agent_id=partition.agent_id
    )

    db.add(new_partition)
    db.commit()
    db.refresh(new_partition)

    #  Convert to GeoJSON
    result = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
        #Partition.agent_id
    ).filter(Partition.id == new_partition.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "superficie": result.superficie,
        "geom": json.loads(result.geom),
        "foret_id": result.foret_id,
        #"agent_id": result.agent_id
    }



def get_partitions(db: Session):

    partitions = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
        #Partition.agent_id
    ).all()

    result = []

    """for p in partitions:
        result.append({
            "id": p.id,
            "nom": p.nom,
            "superficie": p.superficie,
            "geom": json.loads(p.geom),
            "foret_id": p.foret_id,
            "agent_id": p.agent_id
        })"""
    for row in partitions:
        agents = db.query(Utilisateur).filter(
            Utilisateur.partition_id == row.id
        ).all()
        result.append({
            "id": row.id,
            "nom": row.nom,
            "superficie": row.superficie,
            "geom": json.loads(row.geom),
            "foret_id": row.foret_id,
            "agents": [
                {"id": a.id, "nom": a.nom, "prenom": a.prenom, "email": a.email}
                for a in agents
            ],
        })

    return result



def update_partition(db: Session, partition_id: UUID, partition_update: PartitionUpdate):

    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        return None

    update_data = partition_update.model_dump(exclude_unset=True)

    if "geom" in update_data:
        partition.geom = func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(update_data["geom"])), 4326
        )
        # Recalculate superficie when geometry changes
        partition.superficie = _compute_km2(db, update_data["geom"])
        del update_data["geom"]

    for field, value in update_data.items():
        setattr(partition, field, value)

    db.commit()
    db.refresh(partition)

    # Convert to GeoJSON
    result = db.query(
        Partition.id,
        Partition.nom,
        Partition.superficie,
        func.ST_AsGeoJSON(Partition.geom).label("geom"),
        Partition.foret_id,
        #Partition.agent_id
    ).filter(Partition.id == partition.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "superficie": result.superficie,
        "geom": json.loads(result.geom),
        "foret_id": result.foret_id,
        #"agent_id": result.agent_id
    }



def delete_partition(db: Session, partition_id: UUID):

    partition = db.query(Partition).filter(Partition.id == partition_id).first()

    if not partition:
        return None
    
    # Unassign all agents from this partition before deleting
    db.query(Utilisateur).filter(
        Utilisateur.partition_id == partition_id
    ).update({"partition_id": None})

    db.delete(partition)
    db.commit()

    return {"message": "Partition deleted"}

# ── ASSIGN / UNASSIGN AGENT ───────────────────────────────────────────────────

def assign_agent(db: Session, partition_id: UUID, agent_id: UUID) -> dict:
    partition = db.query(Partition).filter(Partition.id == partition_id).first()
    if not partition:
        raise HTTPException(status_code=404, detail="Partition not found")

    agent = db.query(Utilisateur).filter(Utilisateur.id == agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")

    # Enforce: agent can only belong to one partition at a time
    """if agent.partition_id and str(agent.partition_id) != str(partition_id):
        raise HTTPException(
            status_code=400,
            detail="Agent is already assigned to another partition"
        )"""

    agent.partition_id = partition_id
    db.commit()

    return _partition_to_dict(db, partition_id)


def unassign_agent(db: Session, partition_id: UUID, agent_id: UUID) -> dict:
    agent = db.query(Utilisateur).filter(
        Utilisateur.id == agent_id,
        Utilisateur.partition_id == partition_id
    ).first()

    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found in this partition")

    agent.partition_id = None
    db.commit()

    return _partition_to_dict(db, partition_id)
