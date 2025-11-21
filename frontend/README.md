# ICTU-OpenAgri Frontend

React + TypeScript frontend with Clean Architecture.

## Installation

```bash
npm install
```

## Configuration

Copy `.env.example` to `.env`:

```bash
copy .env.example .env
```

## Running

```bash
# Development
npm run dev

# Build
npm run build

# Preview production build
npm run preview
```

## Code Quality

```bash
# Lint
npm run lint

# Format
npm run format
```

## Project Structure

```
src/
├── domain/            # Business entities and repository interfaces
├── application/       # Use cases
├── infrastructure/    # HTTP client and implementations
└── presentation/      # Components, pages, stores
```

## Architecture

This frontend follows Clean Architecture with:
- **Domain Layer**: Business entities and contracts
- **Application Layer**: Use cases
- **Infrastructure Layer**: HTTP client & API integration
- **Presentation Layer**: React components & state management

## Features

- TypeScript for type safety
- React 18 with hooks
- Vite for fast development
- React Router for routing
- Zustand for state management
- Axios for HTTP requests
