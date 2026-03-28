from app.database import SessionLocal

def get_db():
    db = SessionLocal()
    print("Session created")
    try:
        yield db
    finally:
        print("Session closed")
        db.close()