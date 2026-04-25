from jose import jwt

SECRET_KEY = "super-secret-key"

def verify_token(token: str):
    return jwt.decode(token, SECRET_KEY, algorithms=["HS256"])