# 1. 베이스 이미지 선택
FROM python:3.11-slim

# 2. 작업 디렉토리 설정
WORKDIR /code

# 3. 환경 변수 설정
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 4. psycopg2 빌드에 필요한 시스템 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    postgresql-client \
    libpq-dev \
    gcc \
 && rm -rf /var/lib/apt/lists/*

# 5. 파이썬 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 6. 소스 코드 복사
COPY ./app /code/app
ENV PORT=8080
# 7. 서버 실행 (Cloud Run은 PORT 환경 변수를 자동으로 주입)
# main.py 파일이 app/ 폴더 안에 있으므로 app.main:app 으로 지정
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--worker-class", "uvicorn.workers.UvicornWorker", "app.main:app"]
