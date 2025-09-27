from __future__ import annotations
import asyncio
from logging.config import fileConfig
import sys
import logging
from sqlalchemy import create_engine, pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine
from alembic import context
import os

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name:
    try:
        fileConfig(config.config_file_name, disable_existing_loggers=False)
    except Exception:
        # Fallback: basic logging so Alembic won't crash if INI lacks logging sections
        logging.basicConfig(level=logging.INFO)

# Ensure `services/` (project root for backend) is importable as a module root
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# Model metadata
from app.db.base import Base  # ensures Base.metadata includes all models via app.db.base imports
# If you need to force-load models, add more imports here, e.g.:
# from app.models import user, goal, workout  # noqa: F401

target_metadata = Base.metadata

def get_url() -> str:
    # Prefer env var, fall back to alembic.ini's sqlalchemy.url
    url = os.environ.get("DATABASE_URL") or config.get_main_option("sqlalchemy.url")
    if not url:
        raise RuntimeError("DATABASE_URL is not set and sqlalchemy.url is empty in alembic.ini")
    return url

def run_migrations_offline() -> None:
    url = get_url()
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

async def run_migrations_online_async(url: str) -> None:
    connectable = create_async_engine(url, echo=False, poolclass=pool.NullPool)
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online_sync(url: str) -> None:
    engine = create_engine(url, poolclass=pool.NullPool)
    with engine.connect() as connection:
        do_run_migrations(connection)

if context.is_offline_mode():
    run_migrations_offline()
else:
    _url = get_url()
    # Detect common async drivers; adjust if you use different async dialects
    if _url.startswith(("postgresql+asyncpg", "sqlite+aiosqlite", "mysql+aiomysql")):
        asyncio.run(run_migrations_online_async(_url))
    else:
        run_migrations_online_sync(_url)
