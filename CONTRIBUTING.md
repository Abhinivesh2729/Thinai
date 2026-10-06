# Contributing to Thinai

Thank you for your interest in contributing to Thinai! We welcome community contributions to help improve on-device AI for Android.

Please review this guide before submitting issues or pull requests.

---

## Code of Conduct

All contributors and participants are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Getting Started

### Prerequisites

- **Flutter SDK**: Ensure you have a recent stable version of Flutter installed (SDK `^3.11.0` / Flutter `3.27+`).
- **Android SDK & NDK**:
  - Android SDK with API 24+ support.
  - CMake `3.22.1` (available via Android Studio SDK Manager).
  - Android NDK for building native assets (`llama.cpp` via `fllama`).
- An Android device (arm64-v8a recommended) or emulator for testing.

### Fork and Clone

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/Thinai.git
   cd Thinai
   ```
3. Set the upstream remote:
   ```bash
   git remote add upstream https://github.com/ATmega-Software-Technologies/Thinai.git
   ```

### Branch Naming Conventions

Create a dedicated branch for your work:

```bash
git checkout -b <type>/<short-description>
```

Recommended prefixes:
- `feature/` — New functionality or enhancements (e.g., `feature/custom-port-setting`)
- `fix/` — Bug fixes (e.g., `fix/stream-parser-newline`)
- `docs/` — Documentation updates (e.g., `docs/api-guide-curl`)
- `refactor/` — Code refactoring without behavior change

---

## Development Workflow

### 1. Install Dependencies

Fetch all Flutter packages and dependencies:

```bash
flutter pub get
```

### 2. Run the Application

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

> **Note:** The initial build compiles native C/C++ libraries (`llama.cpp`) and may take a few minutes.

### 3. Code Formatting

Format all Dart code before committing:

```bash
dart format .
```

### 4. Static Analysis

Ensure code passes all lints without warnings or errors:

```bash
flutter analyze
```

### 5. Running Tests

Run the test suite excluding tests that require physical on-device LLM models:

```bash
flutter test --exclude-tags native
```

> **Note:** Tests marked with `@Tags(['native'])` require an on-device execution environment and downloaded model weights (see `dart_test.yaml`).

---

## Security and Secrets Policy

Contributors must **never** commit sensitive information, including:
- API keys, access tokens, or bearer tokens
- Passwords or private encryption keys (`*.pem`, `*.key`, `*.p12`, `*.pfx`)
- Environment files (`.env`, `.env.*`)
- Android keystores or signing properties (`*.jks`, `*.keystore`, `key.properties`)
- Service account credential JSON files
- Personal or internal configuration files

Review your changes with `git diff` and `git status` prior to staging and committing.

---

## Pull Request Guidelines

**Target Branch**: All pull requests should target the `main` branch. The `release` branch is reserved for maintainers to trigger production deployments.

1. **Keep PRs Focused**: Address a single feature or bug fix per PR.
2. **Follow Code Quality**: Ensure `dart format .` and `flutter analyze` pass cleanly.
3. **Add or Update Tests**: Include tests covering new functionality or bug fixes.
4. **Fill Out the PR Template**: Provide a clear description of the problem solved, testing performed, and screenshots for any UI modifications.
5. **Clean Commit History**: Write clear, descriptive commit messages (e.g., `Fix context window clamping for imported GGUF models`).

---

## Reporting Issues

### Bug Reports
Before opening a bug report, check existing issues to avoid duplicates. When filing a bug report:
- Use the **Bug Report** template.
- Include clear steps to reproduce, expected behavior, and actual behavior.
- Provide device details, Android version, Flutter/Dart versions, and relevant logs.

### Feature Requests
To suggest a new feature or improvement:
- Use the **Feature Request** template.
- Explain the problem your feature solves and describe the proposed solution.
- Mention any alternatives considered.
