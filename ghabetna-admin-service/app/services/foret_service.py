from sqlalchemy.orm import Session
from app.models.foret import Foret
from app.schemas.foret_schema import ForetCreate , ForetUpdate
import json
from sqlalchemy import func



def create_forest(db: Session, forest: ForetCreate):

    new_forest = Foret(
        nom=forest.nom,
        geom=func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(forest.geom)), 4326
        ),
        location=func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(forest.location)), 4326
        ) if forest.location else None,
        created_by=forest.created_by,
        supervised_by=forest.supervised_by
    )

    db.add(new_forest)
    db.commit()
    db.refresh(new_forest)

    result = db.query(
        Foret.id,
        Foret.nom,
        func.ST_AsGeoJSON(Foret.geom).label("geom"),
        func.ST_AsGeoJSON(Foret.location).label("location"),
        Foret.created_by,
        Foret.supervised_by
    ).filter(Foret.id == new_forest.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "geom": json.loads(result.geom),
        "location": json.loads(result.location) if result.location else None,
        "created_by": result.created_by,
        "supervised_by": result.supervised_by
    }


def get_forests(db: Session):

    forests = (
        db.query(
            Foret.id,
            Foret.nom,
            func.ST_AsGeoJSON(Foret.geom).label("geom"),
            func.ST_AsGeoJSON(Foret.location).label("location"),
            Foret.created_by,
            Foret.supervised_by
        )
        .all()
    )

    result = []

    for f in forests:
        result.append({
            "id": f.id,
            "nom": f.nom,
            "geom": json.loads(f.geom),
            "location": json.loads(f.location) if f.location else None,
            "created_by": f.created_by,
            "supervised_by": f.supervised_by
        })

    return result


def update_forest(db: Session, forest_id: str, forest_update: ForetUpdate):

    forest = db.query(Foret).filter(Foret.id == forest_id).first()

    if not forest:
        return None

    update_data = forest_update.model_dump(exclude_unset=True)

    if "geom" in update_data:
        forest.geom = func.ST_SetSRID(
            func.ST_GeomFromGeoJSON(json.dumps(update_data["geom"])), 4326
        )
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

    result = db.query(
        Foret.id,
        Foret.nom,
        func.ST_AsGeoJSON(Foret.geom).label("geom"),
        func.ST_AsGeoJSON(Foret.location).label("location"),
        Foret.created_by,
        Foret.supervised_by
    ).filter(Foret.id == forest.id).first()

    return {
        "id": result.id,
        "nom": result.nom,
        "geom": json.loads(result.geom),
        "location": json.loads(result.location) if result.location else None,
        "created_by": result.created_by,
        "supervised_by": result.supervised_by
    }


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
