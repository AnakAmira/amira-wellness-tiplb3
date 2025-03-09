# Amira Wellness Backend

![Python 3.11+](https://img.shields.io/badge/python-3.11%2B-blue.svg)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104%2B-green.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-blue.svg)
![Docker](https://img.shields.io/badge/Docker-ready-blue.svg)

Backend services for the Amira Wellness application, a mobile platform for emotional well-being through voice journaling, emotional check-ins, and self-regulation tools.

## Overview

The Amira Wellness backend provides RESTful API services for the mobile applications, handling user authentication, voice journal storage, emotional data processing, tool library management, and progress tracking. The system is designed with privacy and security as core principles, implementing end-to-end encryption for sensitive user data.

## Features

- Secure user authentication and profile management
- End-to-end encrypted voice journal storage
- Emotional state tracking and analysis
- Tool library content management
- Progress and streak tracking
- Notification management
- Background processing for analytics and recommendations

## Architecture

The backend follows a modular architecture with the following components:

- **API Layer**: FastAPI-based REST endpoints
- **Service Layer**: Business logic implementation
- **Data Access Layer**: Database interactions via SQLAlchemy
- **Background Workers**: Asynchronous task processing
- **Core Services**: Encryption, storage, and shared utilities

### Directory Structure

```
app/
├── api/            # API routes and endpoints
├── background/     # Background tasks and workers
├── constants/      # Application constants
├── core/           # Core functionality and config
├── crud/           # Database operations
├── db/             # Database setup and session
├── middleware/     # Request/response middleware
├── models/         # SQLAlchemy models
├── schemas/        # Pydantic schemas
├── services/       # Business logic services
└── utils/          # Utility functions
```

## Getting Started

### Prerequisites

- Python 3.11+
- PostgreSQL 15+
- Docker and Docker Compose (optional)
- AWS account for S3 storage (production)

### Environment Setup

1. Clone the repository
2. Create a virtual environment: `python -m venv venv`
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Unix/MacOS: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Copy `.env.example` to `.env` and configure environment variables

### Database Setup

1. Create a PostgreSQL database
2. Update database connection string in `.env`
3. Run migrations: `alembic upgrade head`
4. (Optional) Seed initial data: `python -m scripts.seed_db`

### Running the Application

**Development mode:**
```
uvicorn main:app --reload
```

**Production mode:**
```
gunicorn -c gunicorn.conf.py main:app
```

**Docker:**
```
docker-compose up -d
```

## Development

### Code Style

This project follows PEP 8 style guidelines. We use flake8 for linting and black for code formatting.

Format code before committing:
```
black .
```

Lint code:
```
flake8
```

### Testing

Run tests with pytest:
```
pytest
```

With coverage report:
```
pytest --cov=app tests/
```

### Database Migrations

Create a new migration after model changes:
```
alembic revision --autogenerate -m "description"
```

Apply migrations:
```
alembic upgrade head
```

## API Documentation

When the application is running, API documentation is available at:

- Swagger UI: `/docs`
- ReDoc: `/redoc`

These provide interactive documentation for all available endpoints.

## Deployment

Deployment configurations are available in the `deploy/` directory:

- Docker: `deploy/docker-compose.prod.yml`
- Kubernetes: `deploy/kubernetes/`
- AWS ECS: `deploy/aws/`

Refer to the deployment documentation in `docs/deployment/backend-deployment.md` for detailed instructions.

## Security

The backend implements several security measures:

- End-to-end encryption for voice recordings and sensitive data
- JWT-based authentication with secure token handling
- HTTPS-only communication
- Database encryption at rest
- Input validation and sanitization
- Rate limiting and brute force protection

Security vulnerabilities should be reported according to the process in SECURITY.md.

## License

This project is licensed under the terms specified in the LICENSE file.