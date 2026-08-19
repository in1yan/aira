import re

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.config import settings


class RegisterRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    name: str = Field(min_length=1, max_length=255)
    password: str = Field(min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        value = value.strip().lower()
        if "@" not in value or value.startswith("@") or value.endswith("@"):
            raise ValueError("Enter a valid email address")
        return value

    @field_validator("name")
    @classmethod
    def normalize_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Name cannot be blank")
        return value

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        requirements = [
            (len(value) >= settings.PASSWORD_MIN_LENGTH, f"at least {settings.PASSWORD_MIN_LENGTH} characters"),
            (not settings.PASSWORD_REQUIRE_UPPERCASE or bool(re.search(r"[A-Z]", value)), "an uppercase letter"),
            (not settings.PASSWORD_REQUIRE_LOWERCASE or bool(re.search(r"[a-z]", value)), "a lowercase letter"),
            (not settings.PASSWORD_REQUIRE_DIGIT or bool(re.search(r"\d", value)), "a digit"),
            (not settings.PASSWORD_REQUIRE_SPECIAL or bool(re.search(r"[^A-Za-z0-9]", value)), "a special character"),
        ]
        missing = [description for valid, description in requirements if not valid]
        if missing:
            raise ValueError(f"Password must contain {', '.join(missing)}")
        return value


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=1)


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    name: str
    avatar_url: str | None = None
    is_active: bool
    is_superuser: bool
    role: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse
