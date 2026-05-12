# Spring Project Instructions

## Development Commands
- Install dependencies: `./mvnw dependency:resolve`
- Run tests: `./mvnw test`
- Run build: `./mvnw clean package`
- Run app: `./mvnw spring-boot:run`

## Coding Guidelines
- Keep controllers thin; put business logic in services.
- Prefer constructor injection.
- Validate external input at API boundaries.
- Keep database changes explicit and migration-backed.

## Claude Workflow
- Inspect controllers, services, repositories, DTOs, and migrations before changing behavior.
- Run targeted tests first, then broader tests when needed.
