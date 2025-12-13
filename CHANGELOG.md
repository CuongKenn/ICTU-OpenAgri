# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2025-12-11

### Added

- **FIWARE Integration**:
  - Added FIWARE services stack (Orion Context Broker, MongoDB, QuantumLeap, CrateDB) to docker-compose.
  - Implemented FIWARE client service with full NGSI-LD support.
  - Added FIWARE configuration settings for environment-based setup.
  - Added REST API endpoints for FIWARE entity management.
  - Integrated FIWARE sync into scheduler for automatic NDVI and soil moisture data publishing.

- **NGSI-LD Data Format**:
  - Added NGSI-LD soil data for 32 Vietnamese provinces.
  - Converted commodity prices data to NGSI-LD format.
  - Refactored pest/disease data structure to NGSI-LD format.

- **Farm Management**:
  - Added PUT and DELETE endpoints for farm API.
  - Implemented `UpdateFarmAreaUseCase` and `DeleteFarmAreaUseCase`.
  - Added `FarmAreaUpdateDTO` for partial farm updates.
  - Added edit/delete UI dialogs for farm management in frontend.
  - Added `updateFarm` and `deleteFarm` service methods.

- **Satellite Data Improvements**:
  - Added `/soil-moisture/get` endpoint for cached soil moisture data.
  - Added `GetSoilMoistureUseCase` for database queries.
  - Added `SoilMoistureQuery` DTOs and models for cached data retrieval.
  - Added Sentinel-1 Soil Moisture scheduled job to scheduler.
  - Expanded Sentinel-1 search range to ±7 days for better data availability.

- **Frontend Enhancements**:
  - Redesigned satellite monitoring screen with modern layout.
  - Translated commodity categories to Vietnamese.
  - Replaced pest warnings with soil data display.

### Fixed

- **Backend**:
  - Fixed FIWARE service endpoint configuration.
  - Added CASCADE DELETE for `satellite_data` foreign key constraints.
  - Fixed operator precedence in B04 band detection.
  - Fixed band path finder to use `IMG_DATA` instead of `QI_DATA` for NDVI calculation.
  - Added exponential backoff and 429 rate limit handling for CDSE downloads.
  - Added retry mechanism for large Sentinel file downloads.
  - Filtered NDVI images by cloud cover < 30%.
  - Added `Attributes` expand to CDSE query for cloud cover filtering.
  - Improved soil matching and crop suggestions algorithm.
  - Adjusted soil moisture calibration for raw Sentinel-1 GRD data.
  - Enabled matplotlib for TIFF to PNG conversion in NDVI processing.

- **Frontend**:
  - Fixed RenderFlex overflow in `PestRiskCard` with Expanded and Wrap widgets.
  - Fixed RenderFlex overflow in `_buildDetailRow` with Flexible wrapper.
  - Fixed deactivated widget lookup by storing ViewModel references.
  - Fetched real NDVI values for dashboard stats.
  - Removed mock data fallback in satellite monitoring.
  - Fixed deprecated `tooltipRoundedRadius` → `tooltipBorderRadius`.

### Changed

- **Backend**:
  - Replaced `print()` statements with proper logging throughout backend.
  - Updated commodity price service to use NGSI-LD format.
  - Renamed `vietnam_pest_mock_data` to `vietnam_pest_ngsi_ld`.
  - Updated FIWARE stack to latest versions with stable MongoDB.

- **Frontend**:
  - Renamed `SatelliteMonitoringScreenV2` to `SatelliteMonitoringScreen`.
  - Updated viewmodel to use cached soil moisture API.
  - Fetched all satellite data in parallel on initialization.
  - Upgraded `fl_chart` from 0.69.0 to 1.1.1.
  - Removed all `debugPrint` statements for production readiness.

### Performance

- Added coordinate-based cache for pest forecast API.
- Parallel fetching of satellite data on screen initialization.
- Added retry mechanism and job improvements to scheduler.

### Documentation

- Updated README with FIWARE integration and NGSI-LD documentation.
- Added build/compile instructions for mobile app in README.
- Added `MAX_PRODUCTS` to environment example file.

### Chores

- Added `pyproj` dependency for bbox cropping.
- Updated license headers across source files.
- Removed old `mock_commodity_prices.json` file.
- Increased `MAX_PRODUCTS` default to 20.

## [0.2.2] - 2025-12-05

### Fixed

- **Backend**:
  - Fixed `500 Internal Server Error` in "Create Farm" API by manually serializing coordinate objects to JSON, resolving Pydantic serialization issues.
  - Restored missing Vietnamese disease names (`_vietnamese_names`) in `DiseaseDetectionService` that were accidentally removed during refactoring.
  - Fixed variable name error (`max_value` -> `max_val`) in `NDVIUseCase`.
  - Fixed import issues in `VietnamPestService`.
- **Frontend**:
  - Fixed Admin redirection issue where reloading the page would redirect admins to the user dashboard.
  - Robustly parsed `is_superuser` and `is_active` fields in `User` model to handle various data types (boolean, int, string).
  - Formatted "Area" and "Soil Moisture" values to 2 decimal places in Dashboard and Satellite Monitoring screens.
  - Fixed linter errors (deprecated `withOpacity`, `prefer_final_locals`) in `PestForecastTab`.

### Added

- **Backend**:
  - Implemented **Background Scheduler** (using `APScheduler`) to automatically sync NDVI data for farms daily.
  - Added `sync_latest_data_for_farm` use case to fetch and store the top 10 most recent Sentinel-2 images for each farm.
  - Added automatic cleanup logic to remove temporary files (`.zip`, `.SAFE`, `.tif`) after processing to save disk space.
  - Added caching for Commodity Price mock data to improve performance.
  - Added `VietnamPestService` to load pest data from external JSON files instead of hardcoded Python dictionaries.

### Changed

- **Backend**:
  - **Performance Optimization**: Converted `SentinelClient` to fully **Async/Await** using `httpx` and `ThreadPoolExecutor` for non-blocking I/O and CPU-bound tasks (unzipping).
  - Refactored `NDVIUseCase`, `SoilMoistureUseCase`, and `DiseaseDetectionService` to be fully asynchronous.
  - Moved hardcoded pest mock data to `backend/data/mock_pest_data.json`.
  - Updated `DiseaseDetectionService` to run TensorFlow predictions in a thread pool to prevent blocking the event loop.

## [0.2.1] - 2025-12-03

### Added

- **Admin Panel**:
  - Implemented comprehensive Admin Dashboard with crop distribution charts and interactive farm map.
  - Added "Farms" (Vùng Trồng) tab with list view and "View Details" navigation.
  - Enhanced Farm Map with satellite view, fullscreen mode, and polygon boundaries.
  - Added owner information to farm markers and details.
  - Implemented User Management UI.
  - Added Planting Area management.
  - Redesigned layout with bottom navigation bar.
- **Backend**:
  - Added automatic Admin Account creation on startup (configurable via env vars).
  - Implemented historical satellite data storage (SatelliteDataModel) and retrieval.
  - Added endpoints for crop distribution statistics and farm locations.
  - Added `farm_id` support to NDVI analysis for farm-specific monitoring.
  - Added `check_db` script for database diagnostics.
- **Frontend**:
  - Added `SplashView` for auto-login and persistent session management.
  - Integrated `farm_id` into satellite data requests.
  - Added license headers to all source files.

### Fixed

- **Backend**:
  - Fixed Disease Detection API: corrected JSON key mismatch (`class_name` vs `vietnamese_name`) and image preprocessing.
  - Fixed 500 error in farm locations endpoint (serialization issue).
  - Fixed Pydantic validation errors in admin endpoints.
- **Frontend**:
  - Updated `DiseasePredictionDTO` to handle flexible JSON keys from backend.

### Changed

- **Backend**:
  - Refactored Admin User creation to occur during application lifespan events.
  - Updated JWT security implementation.
  - Refactored image processing utilities.
- **Documentation**:
  - Updated README with bug tracker links.
  - Added license headers to source code.

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
