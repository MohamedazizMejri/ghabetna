from fastapi import FastAPI
from app.routes import incident_router
from app import models 
from fastapi.staticfiles import StaticFiles

from fastapi.middleware.cors import CORSMiddleware

from app.core.redis_subscriber import start_subscriber
from app.routes import profile_router   



from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    start_subscriber()
    yield
    # shutdown (add cleanup here if needed later)

app = FastAPI(lifespan=lifespan)

app.include_router(incident_router.router)

app.include_router(profile_router.router)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for dev (later restrict)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)