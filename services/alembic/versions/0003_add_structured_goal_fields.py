"""Add structured goal fields

Revision ID: 0003_add_goal_fields
Revises: 0002_domain_schema
Create Date: 2025-09-27
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "0003_add_structured_goal_fields"
down_revision = "0002_domain_schema"
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Add new columns to goals table
    op.add_column(
        "goals",
        sa.Column("start_date", sa.Date(), nullable=False),
    )
    op.add_column(
        "goals",
        sa.Column("end_date", sa.Date(), nullable=False),
    )
    op.add_column(
        "goals",
        sa.Column("weekly_sessions", sa.Integer(), nullable=False),
    )
    op.add_column(
        "goals",
        sa.Column("session_minutes", sa.Integer(), nullable=False),
    )

def downgrade() -> None:
    # Drop the columns if rolling back
    op.drop_column("goals", "start_date")
    op.drop_column("goals", "end_date")
    op.drop_column("goals", "weekly_sessions")
    op.drop_column("goals", "session_minutes")