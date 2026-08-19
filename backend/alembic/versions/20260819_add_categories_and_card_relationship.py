"""add categories and card category relationships

Revision ID: 20260819_add_categories
Revises: 360df2a935a7
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260819_add_categories"
down_revision: str | None = "360df2a935a7"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    tables = set(inspector.get_table_names())
    if "categories" not in tables:
        op.create_table(
            "categories",
            sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
            sa.Column("name", sa.String(length=255), nullable=False),
            sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("banner_url", sa.String(length=500), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index("ix_categories_id", "categories", ["id"], unique=False)

    if "card_categories" not in tables:
        op.create_table(
            "card_categories",
            sa.Column("card_id", sa.Integer(), nullable=False),
            sa.Column("category_id", sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(["card_id"], ["cards.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["category_id"], ["categories.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("card_id", "category_id"),
        )


def downgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    tables = set(inspector.get_table_names())
    if "card_categories" in tables:
        op.drop_table("card_categories")
    if "categories" in tables:
        op.drop_index("ix_categories_id", table_name="categories")
        op.drop_table("categories")
