.PHONY: dev run test

dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port $${APP_PORT:-8000}

run:
	uvicorn app.main:app --host 0.0.0.0 --port $${APP_PORT:-8000}

test:
	pytest -q


db.up:
	docker compose up -d db

db.migrate:
	alembic upgrade head

db.downgrade:
	alembic downgrade -1

db.revision:
	alembic revision -m "$(m)" --autogenerate
