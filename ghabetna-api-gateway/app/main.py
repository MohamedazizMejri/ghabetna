from fastapi import FastAPI, Request
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
import httpx

app = FastAPI(title="Ghabetna API Gateway")

# ==========================================
# CORS
# ==========================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# MICROSERVICES URLS
# ==========================================

ADMIN_SERVICE = "http://127.0.0.1:8000"
INCIDENT_SERVICE = "http://127.0.0.1:8001"

# ==========================================
# GENERIC PROXY FUNCTION
# ==========================================

async def proxy_request(request: Request, target_url: str):

    async with httpx.AsyncClient(timeout=60.0) as client:

        body = await request.body()

        response = await client.request(
            method=request.method,
            url=target_url,
            content=body,
            headers=dict(request.headers),
            params=dict(request.query_params)
        )

    excluded_headers = [
        "content-encoding",
        "content-length",
        "transfer-encoding",
        "connection"
    ]

    headers = {
        key: value
        for key, value in response.headers.items()
        if key.lower() not in excluded_headers
    }

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=headers
    )

# ==========================================
# ROOT
# ==========================================

@app.get("/")
def root():
    return {
        "message": "Ghabetna API Gateway Running"
    }

# ==========================================
# AUTH ROUTES
# ==========================================

@app.api_route("/auth", methods=["GET", "POST"])
@app.api_route(
    "/auth/{path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE"]
)
async def auth_proxy(path: str = "", request: Request = None):

    target_url = f"{ADMIN_SERVICE}/auth/"

    if path:
        target_url += path       # f"/{path}"

    return await proxy_request(request, target_url)

# ==========================================
# USERS ROUTES
# ==========================================

@app.api_route("/users", methods=["GET", "POST"])
@app.api_route(
    "/users/{path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE"]
)
async def users_proxy(path: str = "", request: Request = None):

    target_url = f"{ADMIN_SERVICE}/users/"

    if path:
        target_url += path

    return await proxy_request(request, target_url)

# ==========================================
# ROLES ROUTES
# ==========================================

@app.api_route("/roles", methods=["GET"])
@app.api_route(
    "/roles/{path:path}",
    methods=["GET"]
)
async def roles_proxy(path: str = "", request: Request = None):

    target_url = f"{ADMIN_SERVICE}/roles/"

    if path:
        target_url += path

    return await proxy_request(request, target_url)

# ==========================================
# FORESTS ROUTES
# ==========================================

@app.api_route("/forests", methods=["GET", "POST"])
@app.api_route(
    "/forests/{path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE"]
)
async def forests_proxy(path: str = "", request: Request = None):

    target_url = f"{ADMIN_SERVICE}/forests/"

    if path:
        target_url += path

    return await proxy_request(request, target_url)

# ==========================================
# PARTITIONS ROUTES
# ==========================================

@app.api_route("/partitions", methods=["GET", "POST"])
@app.api_route(
    "/partitions/{path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE"]
)
async def partitions_proxy(path: str = "", request: Request = None):

    target_url = f"{ADMIN_SERVICE}/partitions/"

    if path:
        target_url += path

    return await proxy_request(request, target_url)

# ==========================================
# STATS ROUTES
# ==========================================

@app.api_route("/stats", methods=["GET"])
@app.api_route(
    "/stats/{path:path}",
    methods=["GET"]
)
async def stats_proxy(path: str = "", request: Request = None):

    target_url = f"{ADMIN_SERVICE}/stats/"

    if path:
        target_url += path

    return await proxy_request(request, target_url)

# ==========================================
# INCIDENTS ROUTES
# ==========================================

@app.api_route("/incidents", methods=["GET", "POST"])
@app.api_route(
    "/incidents/{path:path}",
    methods=["GET", "POST", "PUT", "PATCH", "DELETE"]
)
async def incidents_proxy(path: str = "", request: Request = None):

    target_url = f"{INCIDENT_SERVICE}/incidents"

    if path:
        target_url += f"/{path}"

    return await proxy_request(request, target_url)

# ==========================================
# INCIDENT TYPES ROUTES
# ==========================================

@app.api_route("/incident-types", methods=["GET"])
@app.api_route(
    "/incident-types/{path:path}",
    methods=["GET"]
)
async def incident_types_proxy(path: str = "", request: Request = None):

    target_url = f"{INCIDENT_SERVICE}/incident-types"

    if path:
        target_url += f"/{path}"

    return await proxy_request(request, target_url)

# ==========================================
# UPLOADS ROUTES
# ==========================================

@app.api_route(
    "/uploads/{path:path}",
    methods=["GET"]
)
async def uploads_proxy(path: str, request: Request = None):

    target_url = f"{INCIDENT_SERVICE}/uploads/{path}"

    return await proxy_request(request, target_url)