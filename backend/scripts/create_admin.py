"""Create an admin user from the command line.

Run from the backend directory:
    python -m scripts.create_admin
"""

import argparse
import getpass

from sqlalchemy.exc import IntegrityError

from app.db.session import SessionLocal, init_db
from app.models.users import User
from app.schemas.auth import RegisterRequest
from app.services.auth import get_user_by_email, hash_password


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create an admin user")
    parser.add_argument("--email", help="Admin email address")
    parser.add_argument("--name", help="Admin display name")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    email = args.email or input("Admin email: ")
    name = args.name or input("Admin name: ")
    password = getpass.getpass("Admin password: ")
    password_confirmation = getpass.getpass("Confirm password: ")

    if password != password_confirmation:
        raise SystemExit("Passwords do not match.")

    try:
        payload = RegisterRequest(email=email, name=name, password=password)
    except ValueError as exc:
        raise SystemExit(f"Invalid admin details: {exc}") from None

    # This supports a fresh local database. Existing databases should be migrated
    # with `alembic upgrade head` before running this command.
    init_db()
    db = SessionLocal()
    try:
        if get_user_by_email(db, payload.email) is not None:
            raise SystemExit(
                "A user with that email already exists; refusing to overwrite it."
            )

        admin = User(
            email=payload.email,
            name=payload.name,
            password_hash=hash_password(payload.password),
            role="admin",
        )
        db.add(admin)
        db.commit()
        created_email = admin.email
    except IntegrityError:
        db.rollback()
        raise SystemExit("A user with that email already exists.") from None
    finally:
        db.close()

    print(f"Created admin user: {created_email}")


if __name__ == "__main__":
    main()
