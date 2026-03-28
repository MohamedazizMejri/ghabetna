from fastapi import FastAPI

from app.routers import user_router
from app.routers import foret_router
from app.routers import role_router
from app.routers import partition_router

from app.routers import auth_router

from app.routers import stats_router

from fastapi.middleware.cors import CORSMiddleware





app = FastAPI(
    title="Ghabetna Admin Service"
)

@app.get("/")
def root():
    return {"message": "Hello, FastAPI + PostgreSQL is working"}




app.include_router(user_router.router)
app.include_router(foret_router.router)
app.include_router(role_router.router)
app.include_router(partition_router.router)


app.include_router(auth_router.router)


app.include_router(stats_router.router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)