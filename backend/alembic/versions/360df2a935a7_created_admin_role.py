"""create admin role and card relationships

Revision ID: 360df2a935a7
Revises: 0001_create_users
Create Date: 2026-08-19
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "360df2a935a7"
down_revision: str | None = "0001_create_users"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _table_names() -> set[str]:
    return set(sa.inspect(op.get_bind()).get_table_names())


def _index_names(table_name: str) -> set[str]:
    return {index["name"] for index in sa.inspect(op.get_bind()).get_indexes(table_name)}


def upgrade() -> None:
    table_names = _table_names()
    users_columns = {column["name"] for column in sa.inspect(op.get_bind()).get_columns("users")}

    if "role" not in users_columns:
        op.add_column(
            "users",
            sa.Column("role", sa.String(length=50), nullable=False, server_default="user"),
        )

    if "cards" not in table_names:
        op.create_table(
            "cards",
            sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
            sa.Column("name", sa.String(length=255), nullable=False),
            sa.Column("user_id", sa.Integer(), nullable=False),
            sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("card_image", sa.String(length=500), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )

    if "ix_cards_id" not in _index_names("cards"):
        op.create_index("ix_cards_id", "cards", ["id"], unique=False)
    if "ix_cards_user_id" not in _index_names("cards"):
        op.create_index("ix_cards_user_id", "cards", ["user_id"], unique=False)

    if "card_attributes" not in table_names:
        op.create_table(
            "card_attributes",
            sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
            sa.Column("card_id", sa.Integer(), nullable=False),
            sa.Column("attribute_image", sa.String(length=500), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.ForeignKeyConstraint(["card_id"], ["cards.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )

    if "ix_card_attributes_id" not in _index_names("card_attributes"):
        op.create_index("ix_card_attributes_id", "card_attributes", ["id"], unique=False)
    if "ix_card_attributes_card_id" not in _index_names("card_attributes"):
        op.create_index("ix_card_attributes_card_id", "card_attributes", ["card_id"], unique=False)


def downgrade() -> None:
    table_names = _table_names()
    if "card_attributes" in table_names:
        for index_name in ("ix_card_attributes_card_id", "ix_card_attributes_id"):
            if index_name in _index_names("card_attributes"):
                op.drop_index(index_name, table_name="card_attributes")
        op.drop_table("card_attributes")

    if "cards" in table_names:
        for index_name in ("ix_cards_user_id", "ix_cards_id"):
            if index_name in _index_names("cards"):
                op.drop_index(index_name, table_name="cards")
        op.drop_table("cards")

    users_columns = {column["name"] for column in sa.inspect(op.get_bind()).get_columns("users")}
    if "role" in users_columns:
        op.drop_column("users", "role")
