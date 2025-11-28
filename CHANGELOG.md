# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-11-28

### Added

- **CI/CD**: Configured GitHub Actions workflow for automated Android release builds.
  - Automatically builds APK on tag push (`v*`).
  - Creates GitHub Release and uploads APK artifact.
- **Backend**: Implemented **Soil Moisture** calculation from Sentinel-1 satellite data.
  - Added logic to calculate mean soil moisture value (0-100%) for a specific area.
  - Updated API to return both visual map and numeric value.
- **Frontend**: Integrated real **Soil Moisture** data into Satellite Monitoring screen.
  - Replaced weather-based mock data with actual Sentinel-1 analysis.
  - Added soil moisture status indicators (Thiếu nước, Đủ ẩm, Dư nước).
- **Frontend**: Integrated real soil moisture data into Dashboard charts.
- **Frontend**: Integrated **Real Farm Data** into Dashboard.
  - Replaced mock farm data with real data fetched from the backend.
  - Implemented farm selection logic in DashboardViewModel.
- **Frontend**: Implemented **Commodity Prices** feature.
  - Added `CommodityPriceService` and `CommodityPriceViewModel`.
  - Integrated with backend API to fetch real market data.
  - Updated UI to display price trends and details.
- **Frontend**: Implemented **Authentication** flow.
  - Integrated `AuthService` with backend API for Login and Sign Up.
  - Added `User` model and token management.
  - Added `/me` endpoint integration to retrieve current user profile.
- **Frontend**: Implemented **Plant Health Monitoring** feature.
  - Added disease detection and analysis screen.
  - Integrated into app navigation.
- **Frontend**: Implemented **Field Map** feature.
  - Added 4-point polygon drawing mode for field definition.
  - Added area calculation functionality.
- **Frontend**: Added **Satellite Monitoring** screen.
  - Added date and layer pickers.
  - Integrated map tiles for satellite imagery.
- **Frontend**: Added **Dashboard** and **Settings** screens.
- **Frontend**: Added comprehensive Theme system with Material 3 support.
- **Backend**: Implemented **Weather Service** module.
  - Added `WeatherService` for fetching weather data.
  - Added `GetWeatherUseCase` and related DTOs.
  - Added REST API endpoint `GET /api/v1/weather`.
  - Added unit tests for weather service.
- **Backend**: Implemented **Change Password** feature.
  - Added `ChangePasswordUseCase` and API endpoint.
  - Updated user repository to handle password hashing.
- **Backend**: Implemented **NDVI** (Normalized Difference Vegetation Index) module.
  - Added Sentinel-2 client for searching and downloading satellite imagery.
  - Added NDVI processing logic using `rasterio` and `numpy`.
  - Added `CalculateNDVIUseCase` and related DTOs.
  - Added REST API endpoint `POST /api/v1/ndvi/calculate`.
  - Added configuration for Copernicus credentials and output directories.
- **Auth**: Added phone number support for Login and Registration.
- **Backend**: Added `aiosqlite` for asynchronous SQLite support.
- **Backend**: Added `email-validator` dependency for Pydantic.
- **Docs**: Added Contributor Covenant Code of Conduct.
- **Docs**: Added Contributing guidelines.
- **Docs**: Added MIT License.

### Changed

- **Backend**: **Performance Optimization** - Optimized satellite image processing.
  - Now reads only the specific bounding box (window) of the user's farm instead of the entire satellite image.
  - Significantly reduced processing time and memory usage for Soil Moisture analysis.
- **Frontend**: Improved UI visibility for Map controls.
  - Increased size and contrast of Zoom In/Out buttons on Satellite and Farm Map screens.
- **Frontend**: **Major Refactor** - Migrated frontend from React.js to **Flutter**.
  - Updated Dockerfile for Flutter Web.
  - Updated `docker-compose.yml` to support Flutter container.
  - Updated `Makefile` and `package.json` scripts for Dart/Flutter tooling.
- **Frontend**: Improved Mobile UI/UX.
  - Enhanced navigation bar with OpenAgri branding.
  - Refactored Home screen layout.
  - Updated Satellite Monitoring layout.
- **Backend**: Replaced `sentinelsat` dependency with custom OData client using `requests` to support the new Copernicus Data Space Ecosystem.
- **Backend**: Added `/me` endpoint to retrieve current user information.
- **Backend**: Updated CORS configuration to allow all origins for development flexibility.
- **DevOps**: Simplified Docker setup to use a single `docker-compose.yml` file.
- **DevOps**: Updated `lint-staged` to use `npx` for better compatibility.
- **Chore**: Updated `.gitignore` to exclude large AI models (`*.gguf`) and output data.
- **Chore**: Updated project dependencies.

### Fixed

- **Android**: Fixed connectivity issues in Release builds.
  - Added `INTERNET` permission to AndroidManifest.
  - Enabled `usesCleartextTraffic` to allow HTTP connections to the backend.
- **Frontend**: Fixed API configuration for Production environment.
  - Updated Base URL to point to the correct server IP.
  - Increased API timeout to 300 seconds to accommodate long-running satellite data processing.
- **Frontend**: Fixed deprecated `withOpacity` usage by replacing with `withValues`.
- **Frontend**: Optimized Dashboard loading performance.
  - Fetches weather data in the background to prevent UI blocking.
  - Uses last known location to speed up initial weather fetch.
- **Frontend**: Resolved syntax errors and updated `fl_chart` API usage.
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
