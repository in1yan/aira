from fastapi import APIRouter, Depends, HTTPException, Header, status
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from ..database import get_db
from ..models import User
from ..schemas import UserCreate, UserLogin, UserResponse

router = APIRouter(prefix="/api/auth", tags=["Auth"])

class RefreshRequest(BaseModel):
    refresh_token: str

@router.post("/register", response_model=UserResponse)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = User(
        name=user_data.name,
        email=user_data.email,
        password_hash=user_data.password,
        role=user_data.role or "user"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user:
        new_user = User(
            name=credentials.email.split('@')[0].capitalize(),
            email=credentials.email,
            password_hash=credentials.password,
            role="user"
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return {
            "token": "demo_token_aira_123",
            "access_token": "demo_token_aira_123",
            "refresh_token": "demo_refresh_token_aira_123",
            "user": {
                "id": new_user.id,
                "name": new_user.name,
                "email": new_user.email,
                "role": new_user.role or "user",
                "avatar_url": new_user.avatar_url
            }
        }
    
    return {
        "token": "demo_token_aira_123",
        "access_token": "demo_token_aira_123",
        "refresh_token": "demo_refresh_token_aira_123",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role or "user",
            "avatar_url": user.avatar_url
        }
    }

@router.get("/me")
def get_current_user(db: Session = Depends(get_db)):
    user = db.query(User).first()
    if not user:
        return {
            "id": 1,
            "name": "Demo User",
            "email": "demo@aira.ai",
            "role": "user",
            "avatar_url": None
        }
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role or "user",
        "avatar_url": user.avatar_url
    }

@router.post("/refresh")
def refresh_token(payload: RefreshRequest, db: Session = Depends(get_db)):
    return {
        "token": "demo_token_aira_123_refreshed",
        "access_token": "demo_token_aira_123_refreshed",
        "refresh_token": "demo_refresh_token_aira_123",
        "user": {
            "id": 1,
            "name": "Demo User",
            "email": "demo@aira.ai",
            "role": "user"
        }
    }
