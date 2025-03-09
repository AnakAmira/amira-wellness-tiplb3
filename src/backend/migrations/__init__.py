"""
Database Migrations Package

This package contains database migration scripts managed by Alembic.
The migration system enables versioned database schema changes and
ensures consistent database states across environments.

Migration files in this package should not be edited after they've
been applied to any environment, as this could lead to inconsistent
database states.

For creating a new migration:
    alembic revision --autogenerate -m "Description of changes"

For applying migrations:
    alembic upgrade head

For more information on Alembic commands and usage:
    https://alembic.sqlalchemy.org/en/latest/
"""

# Package initialization for Alembic migrations
# This file ensures the migrations directory is treated as a Python package