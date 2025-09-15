# Makefile for Student Attendance System Docker operations

.PHONY: build up down logs clean dev prod

# Build all containers
build:
	docker-compose build

# Start all services in production mode
up:
	docker-compose up -d

# Start all services in development mode
dev:
	docker-compose -f docker-compose.yml -f docker-compose.override.yml up

# Stop all services
down:
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# View backend logs only
logs-backend:
	docker-compose logs -f backend

# Clean up containers and volumes
clean:
	docker-compose down -v
	docker system prune -f

# Production deployment
prod:
	docker-compose -f docker-compose.yml up -d

# Restart backend service
restart-backend:
	docker-compose restart backend

# Shell into backend container
shell-backend:
	docker-compose exec backend /bin/bash

# Shell into database container
shell-database:
	docker-compose exec database /bin/sh