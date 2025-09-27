from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "0004_goals_add_edited_once"
down_revision = "0003_add_structured_goal_fields"
branch_labels = None
depends_on = None

def upgrade():
    # 1) 컬럼 추가: 딱 1회만 수정 허용 여부 기록
    op.add_column(
        "goals",
        sa.Column("edited_once", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )
    # 서버 기본값 제거(선택)
    op.execute("ALTER TABLE goals ALTER COLUMN edited_once DROP DEFAULT")

def downgrade():
    op.drop_column("goals", "edited_once")