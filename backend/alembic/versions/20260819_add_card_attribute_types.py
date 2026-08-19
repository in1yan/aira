"""add types to card attributes

Revision ID: 20260819_add_card_attribute_types
Revises: 20260819_add_categories
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260819_add_card_attribute_types"
down_revision: str | None = "20260819_add_categories"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


ATTRIBUTE_TYPES = ("group", "association", "location", "function", "action", "properties")


def upgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("card_attributes")}
    if "attribute_type" not in columns:
        op.add_column(
            "card_attributes",
            sa.Column("attribute_type", sa.String(length=50), nullable=True),
        )

    # Preserve existing rows while giving them a valid type in the new API.
    op.execute(
        "UPDATE card_attributes SET attribute_type = 'properties' "
        "WHERE attribute_type IS NULL"
    )


def downgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("card_attributes")}
    if "attribute_type" in columns:
        op.drop_column("card_attributes", "attribute_type")
