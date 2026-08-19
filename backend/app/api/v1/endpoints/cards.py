from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependancies.auth import get_current_admin
from app.models.card import Cards
from app.models.card_attr import CardAttributes
from app.models.users import User
from app.schemas.cards import CardCreate, CardResponse

router = APIRouter()


@router.post("", response_model=CardResponse, status_code=status.HTTP_201_CREATED)
def create_card(
    payload: CardCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> Cards:
    card = Cards(
        name=payload.name.strip(),
        user_id=admin.id,
        is_published=payload.is_published,
        card_image=payload.card_image,
        attributes=[
            CardAttributes(attribute_image=attribute.attribute_image)
            for attribute in payload.attributes
        ],
    )
    db.add(card)
    db.commit()
    db.refresh(card)
    return card
