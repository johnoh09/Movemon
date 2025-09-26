# alembic/versions/0002_domain_schema.py
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = "0002_domain_schema"
down_revision = "0001_create_users"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ENUM types
    op.execute("CREATE TYPE goal_status AS ENUM ('success','fail','progress');")
    op.execute("CREATE TYPE gender AS ENUM ('M','F','N');")

    # users
    op.create_table(
        "users",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("email", sa.Text(), nullable=False, unique=True),
        sa.Column("nickname", sa.Text(), nullable=False),
        sa.Column("password", sa.Text(), nullable=False),
        sa.Column("sex", sa.Enum(name="gender", native_enum=False)),  # reference existing type name
        sa.Column("age", sa.Integer(), sa.CheckConstraint("age BETWEEN 0 AND 120")),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # characters
    op.create_table(
        "characters",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("age", sa.Integer(), nullable=False),
        sa.Column("sex", sa.Enum(name="gender", native_enum=False), nullable=False),
        sa.Column("character_type", sa.Text(), nullable=False),
        sa.Column("img_url", sa.Text(), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("age BETWEEN 0 AND 120"),
    )

    # sports
    op.create_table(
        "sports",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # goals
    op.create_table(
        "goals",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("contents", sa.Text(), nullable=False),
        sa.Column("status", sa.Enum(name="goal_status", native_enum=False), server_default=sa.text("'progress'"), nullable=False),
        sa.Column("user_id", sa.BigInteger(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
    )

    # user_characters
    op.create_table(
        "user_characters",
        sa.Column("user_id", sa.BigInteger(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("character_id", sa.BigInteger(), sa.ForeignKey("characters.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("user_id", "character_id"),
    )

    # user_logs
    op.create_table(
        "user_logs",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("user_id", sa.BigInteger(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("weight_kg", sa.Numeric(5, 2), nullable=False),
        sa.Column("height_cm", sa.Numeric(5, 2), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("weight_kg > 0"),
        sa.CheckConstraint("height_cm > 0"),
    )

    # workouts
    op.create_table(
        "workouts",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("user_id", sa.BigInteger(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("sports_id", sa.BigInteger(), sa.ForeignKey("sports.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("duration_sec", sa.Integer(), nullable=False),
        sa.Column("workout_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("duration_sec > 0"),
    )

    # indexes
    op.create_index("idx_goals_user_id", "goals", ["user_id"])
    op.create_index("idx_user_characters_uid", "user_characters", ["user_id"])
    op.create_index("idx_user_characters_cid", "user_characters", ["character_id"])
    op.create_index("idx_user_logs_user_id", "user_logs", ["user_id"])
    op.create_index("idx_workouts_user_id", "workouts", ["user_id"])
    op.create_index("idx_workouts_sports_id", "workouts", ["sports_id"])
    op.create_index("idx_workouts_workout_at", "workouts", ["workout_at"])

    # triggers (updated_at auto set)
    op.execute("""
    CREATE OR REPLACE FUNCTION set_updated_at()
    RETURNS trigger AS $$
    BEGIN
      NEW.updated_at := now();
      RETURN NEW;
    END; $$ LANGUAGE plpgsql;
    """)

    op.execute("CREATE TRIGGER tg_users_updated    BEFORE UPDATE ON users           FOR EACH ROW EXECUTE FUNCTION set_updated_at();")
    op.execute("CREATE TRIGGER tg_char_updated     BEFORE UPDATE ON characters      FOR EACH ROW EXECUTE FUNCTION set_updated_at();")
    op.execute("CREATE TRIGGER tg_sports_updated   BEFORE UPDATE ON sports          FOR EACH ROW EXECUTE FUNCTION set_updated_at();")
    op.execute("CREATE TRIGGER tg_uc_updated       BEFORE UPDATE ON user_characters FOR EACH ROW EXECUTE FUNCTION set_updated_at();")
    op.execute("CREATE TRIGGER tg_workouts_updated BEFORE UPDATE ON workouts        FOR EACH ROW EXECUTE FUNCTION set_updated_at();")


def downgrade() -> None:
    # drop triggers
    op.execute("DROP TRIGGER IF EXISTS tg_workouts_updated ON workouts;")
    op.execute("DROP TRIGGER IF EXISTS tg_uc_updated ON user_characters;")
    op.execute("DROP TRIGGER IF EXISTS tg_sports_updated ON sports;")
    op.execute("DROP TRIGGER IF EXISTS tg_char_updated ON characters;")
    op.execute("DROP TRIGGER IF EXISTS tg_users_updated ON users;")
    op.execute("DROP FUNCTION IF EXISTS set_updated_at;")

    # drop indexes
    for name in [
        "idx_workouts_workout_at","idx_workouts_sports_id","idx_workouts_user_id",
        "idx_user_logs_user_id","idx_user_characters_cid","idx_user_characters_uid",
        "idx_goals_user_id",
    ]:
        op.drop_index(name)

    # drop tables (fks handled by cascade/restrict)
    op.drop_table("workouts")
    op.drop_table("user_logs")
    op.drop_table("user_characters")
    op.drop_table("goals")
    op.drop_table("sports")
    op.drop_table("characters")
    op.drop_table("users")

    # drop types
    op.execute("DROP TYPE IF EXISTS gender;")
    op.execute("DROP TYPE IF EXISTS goal_status;")