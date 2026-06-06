import json
import threading
import redis
import os

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

# TTL for cached data (24 hours — refreshed on every event)
CACHE_TTL = 86400


def _handle_user_updated(r: redis.Redis, data: dict):
    """
    Admin updated a user's basic info (nom, prenom, email, numtel, cin, role).
    We overwrite the profile cache for that user.
    """
    user_id = data.get("user_id")
    if not user_id:
        return

    cache_key = f"user:{user_id}:profile"

    # Read existing cached profile so we don't lose parcelles/forests
    existing_raw = r.get(cache_key)
    if existing_raw:
        try:
            existing = json.loads(existing_raw)
        except Exception:
            existing = {}
    else:
        existing = {}

    # Merge: keep parcelles/forests from cache, update the user fields
    existing.update({
        "user_id": user_id,
        "nom": data.get("nom"),
        "prenom": data.get("prenom"),
        "email": data.get("email"),
        "numtel": data.get("numtel"),
        "cin": data.get("cin"),
        "role": data.get("role"),
    })

    r.setex(cache_key, CACHE_TTL, json.dumps(existing))
    print(f"[Redis Subscriber] profile updated for user {user_id}")


def _handle_partition_assigned(r: redis.Redis, data: dict):
    """
    Admin assigned a partition (parcelle) to an agent.
    We append/update the partition in the agent's parcelles cache.
    """
    agent_id = data.get("agent_id")
    partition_id = data.get("partition_id")
    if not agent_id or not partition_id:
        return

    parcelles_key = f"user:{agent_id}:parcelles"

    """existing_raw = r.get(parcelles_key)
    if existing_raw:
        try:
            parcelles = json.loads(existing_raw)
        except Exception:
            parcelles = []
    else:
        parcelles = []

    # Avoid duplicates: replace if partition already listed
    parcelles = [p for p in parcelles if p.get("partition_id") != partition_id]
    parcelles.append({
        "partition_id": partition_id,
        "partition_nom": data.get("partition_nom"),
    })

    r.setex(parcelles_key, CACHE_TTL, json.dumps(parcelles))
    print(f"[Redis Subscriber] parcelle {partition_id} assigned to agent {agent_id}")"""
    # Agent has ONE partition — just overwrite, don't append
    parcelles_data = [{"partition_id": partition_id, "partition_nom": data.get("partition_nom")}]
    r.setex(parcelles_key, CACHE_TTL, json.dumps(parcelles_data))
    print(f"[Redis Subscriber] parcelle {partition_id} assigned to agent {agent_id}")


def _handle_forest_assigned(r: redis.Redis, data: dict):
    """
    Admin assigned a forest to a supervisor.
    We append/update the forest in the supervisor's forests cache.
    """
    supervisor_id = data.get("supervisor_id")
    forest_id = data.get("forest_id")
    if not supervisor_id or not forest_id:
        return

    forests_key = f"user:{supervisor_id}:forests"

    existing_raw = r.get(forests_key)
    if existing_raw:
        try:
            forests = json.loads(existing_raw)
        except Exception:
            forests = []
    else:
        forests = []

    forests = [f for f in forests if f.get("forest_id") != forest_id]
    forests.append({
        "forest_id": forest_id,
        "forest_nom": data.get("forest_nom"),
    })

    r.setex(forests_key, CACHE_TTL, json.dumps(forests))
    print(f"[Redis Subscriber] forest {forest_id} assigned to supervisor {supervisor_id}")


def _handle_partition_unassigned(r: redis.Redis, data: dict):
    agent_id = data.get("agent_id")
    if not agent_id:
        return

    parcelles_key = f"user:{agent_id}:parcelles"
    r.delete(parcelles_key)
    print(f"[Redis Subscriber] parcelle unassigned from agent {agent_id}")

def _handle_forest_unassigned(r: redis.Redis, data: dict):
    supervisor_id = data.get("supervisor_id")
    forest_id = data.get("forest_id")
    if not supervisor_id or not forest_id:
        return

    forests_key = f"user:{supervisor_id}:forests"
    existing_raw = r.get(forests_key)
    if not existing_raw:
        return

    try:
        forests = json.loads(existing_raw)
    except Exception:
        return

    forests = [f for f in forests if f.get("forest_id") != forest_id]
    r.setex(forests_key, CACHE_TTL, json.dumps(forests))
    print(f"[Redis Subscriber] forest {forest_id} unassigned from supervisor {supervisor_id}")

def _subscriber_loop():
    """Blocking loop. Runs in a daemon thread."""
    r = redis.Redis.from_url(REDIS_URL, decode_responses=True)
    pubsub = r.pubsub()
    pubsub.subscribe("user_updated", "partition_assigned","partition_unassigned", "forest_assigned","forest_unassigned", "spatial_changed")

    print("[Redis Subscriber] Listening on channels: user_updated, partition_assigned, forest_assigned")

    for message in pubsub.listen():
        if message["type"] != "message":
            continue
        channel = message["channel"]
        try:
            data = json.loads(message["data"])
        except Exception as e:
            print(f"[Redis Subscriber] Bad JSON on channel {channel}: {e}")
            continue

        try:
            if channel == "user_updated":
                _handle_user_updated(r, data)
            elif channel == "partition_assigned":
                _handle_partition_assigned(r, data)
            elif channel == "partition_unassigned":
                _handle_partition_unassigned(r, data)
            elif channel == "forest_assigned":
                _handle_forest_assigned(r, data)
            elif channel == "forest_unassigned":
                _handle_forest_unassigned(r, data)
            elif channel == "spatial_changed":      
                _handle_spatial_changed(r, data)
        except Exception as e:
            print(f"[Redis Subscriber] Error handling {channel}: {e}")


def start_subscriber():
    """Call this once at app startup."""
    t = threading.Thread(target=_subscriber_loop, daemon=True)
    t.start()

def _handle_spatial_changed(r: redis.Redis, data: dict):
    """
    A partition or forest was created, updated, or deleted in the admin service.
    We must:
      1. Delete all spatial:* cache keys (the GPS→partition/forest lookup cache).
      2. Delete all incident:*:details cache keys (they embed foret_nom/parcelle_nom).
    This forces a fresh lookup on next request, which will now return the
    correct partition name (or forest-only, or nothing) for every incident.
    """
    # Delete all spatial lookup caches (pattern scan — safe on small datasets)
    spatial_keys = r.keys("spatial:*")
    if spatial_keys:
        r.delete(*spatial_keys)
        print(f"[Redis Subscriber] Deleted {len(spatial_keys)} spatial cache keys")

    # Delete all incident detail caches (they embed the now-stale names)
    detail_keys = r.keys("incident:*:details")
    if detail_keys:
        r.delete(*detail_keys)
        print(f"[Redis Subscriber] Deleted {len(detail_keys)} incident detail caches")

"""def _handle_partition_unassigned(r: redis.Redis, data: dict):
    agent_id = data.get("agent_id")
    partition_id = data.get("partition_id")
    if not agent_id or not partition_id:
        return

    parcelles_key = f"user:{agent_id}:parcelles"
    existing_raw = r.get(parcelles_key)
    if not existing_raw:
        return

    try:
        parcelles = json.loads(existing_raw)
    except Exception:
        return

    # Remove the unassigned partition
    parcelles = [p for p in parcelles if p.get("partition_id") != partition_id]
    r.setex(parcelles_key, CACHE_TTL, json.dumps(parcelles))
    print(f"[Redis Subscriber] parcelle {partition_id} unassigned from agent {agent_id}")"""