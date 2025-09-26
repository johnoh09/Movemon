from sqlalchemy.dialects.postgresql import ENUM as PGEnum

# DB에 이미 존재하는 ENUM 타입 이름을 그대로 사용 (Alembic에서 생성)
GenderEnum = PGEnum("M", "F", "N", name="gender", create_type=False)
GoalStatusEnum = PGEnum("success", "fail", "progress", name="goal_status", create_type=False)