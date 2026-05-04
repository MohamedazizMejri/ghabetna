from fastapi import FastAPI
from app.routes import incident_router
from app import models 
from fastapi.staticfiles import StaticFiles

from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.include_router(incident_router.router)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for dev (later restrict)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)