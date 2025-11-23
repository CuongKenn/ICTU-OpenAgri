# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Backend**: Implemented NDVI (Normalized Difference Vegetation Index) module.
  - Added Sentinel-2 client for searching and downloading satellite imagery.
  - Added NDVI processing logic using `rasterio` and `numpy`.
  - Added `CalculateNDVIUseCase` and related DTOs.
  - Added REST API endpoint `POST /api/v1/ndvi/calculate`.
  - Added configuration for Copernicus credentials and output directories.
- **Backend**: Added `aiosqlite` for asynchronous SQLite support.
- **Backend**: Added `email-validator` dependency for Pydantic.
- **Docs**: Added Contributor Covenant Code of Conduct.
- **Docs**: Added Contributing guidelines.
- **Docs**: Added MIT License.

### Changed

- **Backend**: Replaced `sentinelsat` dependency with custom OData client using `requests` to support the new Copernicus Data Space Ecosystem.
- **Frontend**: **Major Refactor** - Migrated frontend from React.js to **Flutter**.
  - Updated Dockerfile for Flutter Web.
  - Updated `docker-compose.yml` to support Flutter container.
  - Updated `Makefile` and `package.json` scripts for Dart/Flutter tooling.
- **DevOps**: Simplified Docker setup to use a single `docker-compose.yml` file.
- **DevOps**: Updated `lint-staged` to use `npx` for better compatibility.

### Fixed

- **Backend**: Fixed Sentinel-2 API connection issues (403 Forbidden) by migrating to CDSE OData API.
- **Backend**: Fixed missing dependencies for NDVI module (`sentinelsat`, `rasterio`, etc.).
- **Backend**: Fixed `ImportError` for email validation.
- **Git**: Resolved merge conflicts during frontend refactoring.

## [0.1.0] - 2025-11-22

### Added

- **Architecture**: Initial project setup using Clean Architecture.
- **Backend**: FastAPI framework setup.
  - Domain layer (Entities, Repositories).
  - Application layer (Use Cases, DTOs).
  - Infrastructure layer (Database, Config).
  - Presentation layer (API Endpoints).
- **Frontend**: React.js setup (Initial version, later replaced).
  - Domain, Application, Infrastructure, and Presentation layers.
  - State management with Zustand.
  - UI components and routing.
- **DevOps**: Initial Docker and Docker Compose configuration.
- **DevOps**: Added `Makefile` for task automation.
- **DevOps**: Configured Husky and lint-staged for git hooks.
