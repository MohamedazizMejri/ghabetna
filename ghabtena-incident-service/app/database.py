from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "postgresql://postgres@localhost/ghabetna_incident_db"

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


# Test connection
try:
    with engine.connect() as conn:
        print(" Database connected successfully!")
except Exception as e:
    print(" Connection failed:", e)


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()