from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "postgresql://postgres@localhost/ghabetna_admin_db"

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

try:
    with engine.connect() as conn:
        print(" Database connected successfully!")
except Exception as e:
    print(" Connection failed:", e)

Base = declarative_base()