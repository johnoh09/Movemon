# FastAPI Starter

A minimal, production-minded FastAPI starter with health checks, versioned API, env-driven settings, CORS, tests, and Docker.

## Quickstart

```bash
# 1) Create virtual env and install deps
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2) Run dev server (reload)
make dev
# or
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 3) Open: http://127.0.0.1:8000/health and http://127.0.0.1:8000/docs
```

## Project Layout

```
app/
  main.py
  core/config.py
  api/v1/routes.py
tests/
  test_health.py
```

## Environment

Copy `.env.example` to `.env` and adjust values as needed.

## Docker

```bash
docker build -t fastapi-starter:dev .
docker run -p 8000:8000 --env-file .env fastapi-starter:dev
```

## Makefile

- `make dev` — run with reload
- `make run` — run without reload
- `make test` — run tests
- `make fmt` — basic formatting via `ruff` (optional if you add it)
```



## Database (PostgreSQL) Setup

```bash
# 1) Start PostgreSQL
docker compose up -d db

# 2) Copy env
cp .env.example .env

# 3) Run Alembic migrations
# (activate your venv first)
alembic upgrade head
```

### Sample API Calls
- `POST /v1/users` with body: `{ "email": "alice@example.com", "name": "Alice" }`
- `GET /v1/users`
- `GET /v1/users/{id}`
