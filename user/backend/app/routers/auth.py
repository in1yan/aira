from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User
from ..schemas import UserCreate, UserLogin, UserResponse

router = APIRouter(prefix="/api/auth", tags=["Auth"])

@router.post("/register", response_model=UserResponse)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = User(
        name=user_data.name,
        email=user_data.email,
        password_hash=user_data.password
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
            password_hash=credentials.password
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return {
            "token": "demo_token_aira_123",
            "user": {
                "id": new_user.id,
                "name": new_user.name,
                "email": new_user.email
            }
        }
    
    return {
        "token": "demo_token_aira_123",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email
        }
    }
