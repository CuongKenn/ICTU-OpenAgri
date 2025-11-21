# Contributing to ICTU-OpenAgri

We love your input! We want to make contributing to ICTU-OpenAgri as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Pull Request Process

1. Update the README.md with details of changes if needed.
2. Follow the conventional commit message format.
3. The PR will be merged once you have the sign-off of at least one maintainer.

## Conventional Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` A new feature
- `fix:` A bug fix
- `docs:` Documentation only changes
- `style:` Changes that do not affect the meaning of the code
- `refactor:` A code change that neither fixes a bug nor adds a feature
- `perf:` A code change that improves performance
- `test:` Adding missing tests or correcting existing tests
- `chore:` Changes to the build process or auxiliary tools

Example:
```
feat(backend): add user authentication
fix(frontend): resolve navigation issue
docs: update installation guide
```

## Code Style

### Backend (Python)
- Follow PEP 8
- Use type hints
- Write docstrings for all public methods
- Keep functions small and focused

### Frontend (TypeScript/React)
- Follow ESLint configuration
- Use TypeScript strict mode
- Write meaningful component and function names
- Keep components small and reusable

## Testing

- Write unit tests for new features
- Ensure all tests pass before submitting PR
- Aim for high test coverage

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
