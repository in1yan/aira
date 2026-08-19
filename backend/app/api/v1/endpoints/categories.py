from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependancies.auth import get_current_admin
from app.models.categories import Categories
from app.models.users import User
from app.schemas.categories import CategoryCreate, CategoryResponse, CategoryUpdate

router = APIRouter()


@router.get("", response_model=list[CategoryResponse])
def list_categories(db: Session = Depends(get_db)) -> list[Categories]:
    """Return published categories for the mobile/web learning clients."""
    return list(
        db.scalars(
            select(Categories)
            .where(Categories.is_published.is_(True))
            .order_by(Categories.name)
        ).all()
    )


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> Categories:
    category = Categories(
        name=payload.name.strip(),
        is_published=payload.is_published,
        banner_url=payload.banner_url,
    )
    db.add(category)
    try:
        db.commit()
        db.refresh(category)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Category could not be created") from None
    return category


@router.patch("/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: int,
    payload: CategoryUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> Categories:
    category = db.get(Categories, category_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    changes = payload.model_dump(exclude_unset=True)
    if "name" in changes:
        changes["name"] = changes["name"].strip()
    for key, value in changes.items():
        setattr(category, key, value)
    db.commit()
    db.refresh(category)
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> None:
    category = db.get(Categories, category_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(category)
    db.commit()
