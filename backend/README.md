# ICTU-OpenAgri Backend

FastAPI backend with Clean Architecture.

## Installation

```bash
# Create virtual environmentt
python -m venv venv

# Activate virtual environment (Windows)
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
copy .env.example .env
```

## Running

```bash
# Development
uvicorn app.main:app --reload

# Production
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Testing

```bash
# Run tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html
```

## API Documentation

- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

## Project Structure

```
app/
├── domain/            # Business entities and repository interfaces
├── application/       # Use cases and DTOs
├── infrastructure/    # Database, config, implementations
└── presentation/      # API endpoints
```

## Architecture

This backend follows Clean Architecture with:

- **Domain Layer**: Core business logic
- **Application Layer**: Use cases
- **Infrastructure Layer**: Database & external services
- **Presentation Layer**: REST API
