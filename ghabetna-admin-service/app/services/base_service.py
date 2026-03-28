from sqlalchemy.orm import Session


class BaseService:

    def __init__(self, model):
        self.model = model


    def create(self, db: Session, obj_in: dict):
        db_obj = self.model(**obj_in)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj


    def get_all(self, db: Session):
        return db.query(self.model).all()


    def get_by_id(self, db: Session, obj_id):
        return db.query(self.model).filter(self.model.id == obj_id).first()


    def update(self, db: Session, obj_id, obj_update: dict):
        db_obj = self.get_by_id(db, obj_id)

        if not db_obj:
            return None

        for field, value in obj_update.items():
            setattr(db_obj, field, value)

        db.commit()
        db.refresh(db_obj)

        return db_obj


    def delete(self, db: Session, obj_id):
        db_obj = self.get_by_id(db, obj_id)

        if not db_obj:
            return None

        db.delete(db_obj)
        db.commit()

        return db_obj