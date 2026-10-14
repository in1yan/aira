from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Set
from ..database import get_db
from ..models import Category, Card
from ..schemas import CategoryResponse, CategoryCreate, CategoryUpdate, CategoryContentsResponse

router = APIRouter(prefix="/api/categories", tags=["Categories"])

def get_descendant_category_ids(cat_id: int, db: Session) -> Set[int]:
    """
    Recursively collects all descendant category IDs under a given category ID.
    Prevents infinite cycles with a visited set.
    """
    descendants: Set[int] = set()
    queue = [cat_id]
    while queue:
        current = queue.pop(0)
        children = db.query(Category.id).filter(Category.parent_id == current).all()
        for child_row in children:
            cid = child_row[0]
            if cid not in descendants:
                descendants.add(cid)
                queue.append(cid)
    return descendants

def get_category_breadcrumbs(cat: Category, db: Session) -> List[dict]:
    """
    Constructs an ancestor breadcrumb trail from root down to current category.
    """
    crumbs = []
    visited = set()
    curr: Optional[Category] = cat
    while curr and curr.id not in visited:
        visited.add(curr.id)
        crumbs.append({
            "id": curr.id,
            "name_en": curr.name_en,
            "domain": curr.domain or "semantic"
        })
        if curr.parent_id:
            curr = db.query(Category).filter(Category.id == curr.parent_id).first()
        else:
            break
    crumbs.reverse()
    return crumbs

def format_category_response(cat: Category, db: Session) -> dict:
    direct_card_count = db.query(Card).filter(Card.category_id == cat.id).count()
    direct_subcategories_count = db.query(Category).filter(Category.parent_id == cat.id).count()

    descendant_ids = get_descendant_category_ids(cat.id, db)
    if descendant_ids:
        all_ids = descendant_ids | {cat.id}
        total_card_count = db.query(Card).filter(Card.category_id.in_(all_ids)).count()
    else:
        total_card_count = direct_card_count

    breadcrumbs = get_category_breadcrumbs(cat, db)

    return {
        "id": cat.id,
        "parent_id": cat.parent_id,
        "name_en": cat.name_en,
        "name_ta": cat.name_ta or "",
        "name_hi": cat.name_hi or "",
        "name_ml": cat.name_ml or "",
        "icon_name": cat.icon_name or "pets",
        "color_hex": cat.color_hex or "#E8F5E9",
        "domain": cat.domain or "semantic",
        "description": cat.description or "",
        "card_count": direct_card_count,
        "subcategories_count": direct_subcategories_count,
        "total_card_count": total_card_count,
        "breadcrumbs": breadcrumbs
    }

@router.get("", response_model=List[CategoryResponse])
def get_categories(
    domain: Optional[str] = Query(None),
    parent_id: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """
    Returns categories, optionally filtered by domain and/or parent_id.
    - parent_id='root' or 'null': Returns only top-level categories.
    - parent_id='<int>': Returns child categories directly inside that category.
    - omitting parent_id: Returns all categories for the domain (backward compatible).
    """
    query = db.query(Category)
    if domain:
        query = query.filter(Category.domain == domain.strip().lower())

    if parent_id is not None:
        p_clean = parent_id.strip().lower()
        if p_clean in ("root", "null", "none"):
            query = query.filter(Category.parent_id.is_(None))
        elif p_clean.isdigit():
            query = query.filter(Category.parent_id == int(p_clean))

    categories = query.all()
    return [format_category_response(cat, db) for cat in categories]

@router.get("/{category_id}", response_model=CategoryResponse)
def get_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )
    return format_category_response(category, db)

@router.get("/{category_id}/contents", response_model=CategoryContentsResponse)
def get_category_contents(category_id: int, db: Session = Depends(get_db)):
    """
    Folder Explorer convenience endpoint: returns the folder metadata,
    its immediate child subfolders, and its direct flashcards.
    """
    from .cards import format_card_response

    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )

    subcategories = db.query(Category).filter(Category.parent_id == category_id).all()
    cards = db.query(Card).filter(Card.category_id == category_id).all()
    breadcrumbs = get_category_breadcrumbs(category, db)

    return {
        "category": format_category_response(category, db),
        "subcategories": [format_category_response(sub, db) for sub in subcategories],
        "cards": [format_card_response(card, db) for card in cards],
        "breadcrumbs": breadcrumbs
    }

@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(payload: CategoryCreate, db: Session = Depends(get_db)):
    name_clean = (payload.name_en or "").strip()
    if not name_clean:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category English name (name_en) cannot be empty"
        )

    domain_clean = (payload.domain or "semantic").strip().lower()
    parent_id = None

    if payload.parent_id and payload.parent_id > 0:
        parent_cat = db.query(Category).filter(Category.id == payload.parent_id).first()
        if not parent_cat:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Parent category with ID {payload.parent_id} does not exist"
            )
        parent_id = parent_cat.id
        # Subcategory inherits domain from parent folder
        domain_clean = (parent_cat.domain or domain_clean).strip().lower()

    # Check for duplicate category name within the same parent folder and domain
    duplicate_query = db.query(Category).filter(
        Category.name_en.ilike(name_clean),
        Category.domain == domain_clean
    )
    if parent_id is not None:
        duplicate_query = duplicate_query.filter(Category.parent_id == parent_id)
    else:
        duplicate_query = duplicate_query.filter(Category.parent_id.is_(None))

    if duplicate_query.first():
        loc_desc = f"under parent folder ID {parent_id}" if parent_id else f"at root of domain '{domain_clean}'"
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Category with name '{name_clean}' already exists {loc_desc}"
        )

    new_cat = Category(
        name_en=name_clean,
        parent_id=parent_id,
        name_ta=(payload.name_ta or "").strip(),
        name_hi=(payload.name_hi or "").strip(),
        name_ml=(payload.name_ml or "").strip(),
        description=(payload.description or "").strip(),
        icon_name=(payload.icon_name or "pets").strip(),
        color_hex=(payload.color_hex or "#E8F5E9").strip(),
        domain=domain_clean,
    )
    db.add(new_cat)
    db.commit()
    db.refresh(new_cat)
    return format_category_response(new_cat, db)

@router.put("/{category_id}", response_model=CategoryResponse)
def update_category(category_id: int, payload: CategoryUpdate, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )

    target_domain = (payload.domain or category.domain or "semantic").strip().lower()
    target_parent_id = category.parent_id

    # Handle parent folder change
    if payload.parent_id is not None:
        if payload.parent_id <= 0:
            target_parent_id = None
        else:
            if payload.parent_id == category_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="A category/folder cannot be its own parent"
                )
            # Cycle detection
            descendant_ids = get_descendant_category_ids(category_id, db)
            if payload.parent_id in descendant_ids:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot move a category into one of its own subcategories (would create a loop)"
                )
            parent_cat = db.query(Category).filter(Category.id == payload.parent_id).first()
            if not parent_cat:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Target parent category ID {payload.parent_id} not found"
                )
            target_parent_id = parent_cat.id
            target_domain = (parent_cat.domain or target_domain).strip().lower()

        category.parent_id = target_parent_id

    if payload.name_en is not None:
        name_clean = payload.name_en.strip()
        if not name_clean:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category English name cannot be empty"
            )
        # Check duplicate name within the target parent & domain
        duplicate_query = db.query(Category).filter(
            Category.name_en.ilike(name_clean),
            Category.domain == target_domain,
            Category.id != category_id
        )
        if target_parent_id is not None:
            duplicate_query = duplicate_query.filter(Category.parent_id == target_parent_id)
        else:
            duplicate_query = duplicate_query.filter(Category.parent_id.is_(None))

        if duplicate_query.first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category with name '{name_clean}' already exists in this folder location"
            )
        category.name_en = name_clean

    if payload.name_ta is not None:
        category.name_ta = payload.name_ta.strip()
    if payload.name_hi is not None:
        category.name_hi = payload.name_hi.strip()
    if payload.name_ml is not None:
        category.name_ml = payload.name_ml.strip()
    if payload.description is not None:
        category.description = payload.description.strip()
    if payload.icon_name is not None:
        category.icon_name = payload.icon_name.strip()
    if payload.color_hex is not None:
        category.color_hex = payload.color_hex.strip()
    if payload.domain is not None:
        category.domain = target_domain

    db.commit()
    db.refresh(category)
    return format_category_response(category, db)

@router.delete("/{category_id}")
def delete_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )

    category_name = category.name_en

    # Explicit recursive deletion of cards and subcategories to guarantee cascade safety
    descendant_ids = get_descendant_category_ids(category_id, db)
    all_cat_ids = list(descendant_ids) + [category_id]

    # Delete all cards residing in this folder or any of its subfolders
    db.query(Card).filter(Card.category_id.in_(all_cat_ids)).delete(synchronize_session=False)

    # Delete all subcategories
    if descendant_ids:
        db.query(Category).filter(Category.id.in_(descendant_ids)).delete(synchronize_session=False)

    # Delete target category
    db.delete(category)
    db.commit()

    return {
        "message": f"Category folder '{category_name}' and all subfolders/cards deleted successfully",
        "id": category_id,
        "deleted_count": len(all_cat_ids)
    }
