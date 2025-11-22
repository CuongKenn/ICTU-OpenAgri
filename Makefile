.PHONY: help install dev build up down clean test

help:
	@echo "ICTU-OpenAgri - Makefile Commands"
	@echo ""
	@echo "Development:"
	@echo "  make install        - Install all dependencies"
	@echo "  make dev           - Start development servers"
	@echo "  make dev-docker    - Start development with Docker"
	@echo ""
	@echo "Production:"
	@echo "  make build         - Build Docker images"
	@echo "  make up            - Start production containers"
	@echo "  make down          - Stop all containers"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean         - Clean all generated files"
	@echo "  make test          - Run tests"
	@echo "  make logs          - View container logs"

install:
	@echo "Installing backend dependencies..."
	cd backend && pip install -r requirements.txt
	@echo "Installing frontend dependencies..."
	cd frontend && npm install
	@echo "Installation complete!"

dev:
	@echo "Starting development servers..."
	@echo "Backend will run on http://localhost:8000"
	@echo "Frontend will run on http://localhost:3000"
	@powershell -Command "Start-Process powershell -ArgumentList '-NoExit', '-Command', 'cd backend; uvicorn app.main:app --reload'"
	@powershell -Command "Start-Process powershell -ArgumentList '-NoExit', '-Command', 'cd frontend; npm run dev'"

dev-docker:
	docker-compose -f docker-compose.yml up --build

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

clean:
	@echo "Cleaning generated files..."
	cd backend && rmdir /s /q __pycache__ 2>nul || true
	cd frontend && rmdir /s /q node_modules dist 2>nul || true
	docker-compose down -v
	@echo "Clean complete!"

test:
	@echo "Running backend tests..."
	cd backend && pytest
	@echo "Running frontend tests..."
	cd frontend && npm run test

restart:
	docker-compose restart

ps:
	docker-compose ps
