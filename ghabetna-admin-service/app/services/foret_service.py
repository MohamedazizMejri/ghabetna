from sqlalchemy.orm import Session
from app.models.foret import Foret
from app.schemas.foret_schema import ForetCreate , ForetUpdate
import json
from sqlalchemy import func

def _compute_km2(db: Session, geom_json: dict) -> float:
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
    return round(result / 1_000_000, 6) if result else None

def _query_forest(db: Session, forest_id):
    return db.query(
        Foret.id,
        Foret.nom,
        func.ST_AsGeoJSON(Foret.geom).label("geom"),
        func.ST_AsGeoJSON(Foret.location).label("location"),
        Foret.superficie_km2,
        Foret.region,
        Foret.created_by,
        Foret.supervised_by,
    ).filter(Foret.id == forest_id).first()
 
 
def _row_to_dict(result) -> dict:
    return {
        "id": result.id,
        "nom": result.nom,
        "geom": json.loads(result.geom),
        "location": json.loads(result.location) if result.location else None,
        "superficie_km2": result.superficie_km2,
        "region": result.region,
        "created_by": result.created_by,
        "supervised_by": result.supervised_by,
    }

def create_forest(db: Session, forest: ForetCreate):

    new_forest = Foret(
        nom=forest.nom,
        geom=func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(forest.geom)), 4326
        ),
        location=func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(forest.location)), 4326
        ) if forest.location else None,
        superficie_km2=_compute_km2(db, forest.geom),
        region=forest.region,
        created_by=forest.created_by,
        supervised_by=forest.supervised_by
    )

    db.add(new_forest)
    db.commit()
    db.refresh(new_forest)

    return _row_to_dict(_query_forest(db, new_forest.id))


def get_forests(db: Session):

    forests = (
        db.query(
            Foret.id,
            Foret.nom,
            func.ST_AsGeoJSON(Foret.geom).label("geom"),
            func.ST_AsGeoJSON(Foret.location).label("location"),
            Foret.superficie_km2, Foret.region,
            Foret.created_by,
            Foret.supervised_by
        )
        .all()
    )

    return [_row_to_dict(f) for f in forests]


def update_forest(db: Session, forest_id: str, forest_update: ForetUpdate):

    forest = db.query(Foret).filter(Foret.id == forest_id).first()

    if not forest:
        return None

    update_data = forest_update.model_dump(exclude_unset=True)

    if "geom" in update_data:
        forest.geom = func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(update_data["geom"])), 4326
        )
        forest.superficie_km2 = _compute_km2(db, update_data["geom"])
        del update_data["geom"]

    if "location" in update_data and update_data["location"]:
        forest.location = func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(update_data["location"])), 4326
        )
        del update_data["location"]

    for field, value in update_data.items():
        setattr(forest, field, value)

    db.commit()
    db.refresh(forest)
    return _row_to_dict(_query_forest(db, forest.id))

def delete_forest(db: Session, forest_id: str):

    forest = db.query(Foret).filter(Foret.id == forest_id).first()

    if not forest:
        return None

    db.delete(forest)
    db.commit()

    return {"message": "Forest deleted"}

def assign_supervisor(db: Session, forest_id: str, supervisor_id: str):

    forest = db.query(Foret).filter(Foret.id == forest_id).first()

    if not forest:
        return None

    forest.supervised_by = supervisor_id

    db.commit()
    db.refresh(forest)

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

