from fastapi import FastAPI
from app.routes import incident_router
from app import models 

app = FastAPI()

app.include_router(incident_router.router)