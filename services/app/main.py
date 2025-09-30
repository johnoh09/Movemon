import os

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from dotenv import load_dotenv

from .core.config import settings
from .api.v1.routes import api as v1_api
# --- MODIFIED ---
# engine을 직접 가져와서 연결 테스트에 사용합니다.
from .db.session import init_models, engine 

# .env 파일을 명시적으로 로드합니다.
# FastAPI가 시작될 때 자동으로 로드되지만, 명시하는 것이 더 안전합니다.
load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- MOVED & MODIFIED ---
    # 애플리케이션 시작 시 실행될 로직
    print("🚀 애플리케이션 시작...")
    
    # 개발 환경일 때만 DB 연결 테스트 및 테이블 자동 생성을 시도합니다.
    if settings.app_env == "dev":
        try:
            # 1. 데이터베이스 연결 테스트
            print("... 데이터베이스 연결 테스트 중 ...")
            async with engine.connect() as conn:
                # 간단한 쿼리로 연결이 살아있는지 확인합니다.
                result = await conn.execute(text("SELECT 1"))
                if result.scalar_one() == 1:
                    print("✅ 데이터베이스 연결 성공!")
                else:
                    print("⚠️ 데이터베이스 연결은 되었으나, 테스트 쿼리 결과가 예상과 다릅니다.")

            # 2. 모델 초기화 (테이블 생성)
            print("... 데이터베이스 모델 초기화 중 ...")
            await init_models()
            print("✅ 데이터베이스 모델 초기화 완료.")

        except Exception as e:
            # 데이터베이스가 준비되지 않아도 앱 자체는 시작되도록 합니다.
            print(f"🔥 데이터베이스 연결 또는 초기화 실패: {e}")
            print("🔥 DB 없이 애플리케이션을 시작합니다. 실제 마이그레이션은 Alembic을 사용하세요.")
            pass
            
    yield
    
    # 애플리케이션 종료 시 실행될 로직
    print("🔌 애플리케이션 종료...")
    await engine.dispose()


app = FastAPI(title=settings.app_name, lifespan=lifespan)


# --- REMOVED ---
# 아래 두 블록은 에러의 원인이었으며, lifespan으로 기능이 통합되어 삭제되었습니다.
# async def async_main() -> None:
#     ...
# asyncio.run(async_main())


# CORS 미들웨어 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["health"])
async def root_health():
    """헬스 체크 엔드포인트"""
    return {"status": "ok", "service": settings.app_name, "env": settings.app_env}

# v1 API 라우터 포함
app.include_router(v1_api, prefix="/v1")
