# Contributing to Wordlist Elicitation Tool (PWA)

Thanks for your interest in contributing! This project is a browser-based PWA implemented with vanilla HTML/CSS/JS. Flutter/Dart is no longer used.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment for all contributors

## Getting Started

### Prerequisites

1. **Node.js 18+**
2. **Git**
3. A modern browser (Chrome/Edge/Firefox/Safari)

### Setup Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Quickstart_Android.git
   cd Quickstart_Android
   ```

3. Run locally:
  ```bash
  npm install
  npm start
  # open http://127.0.0.1:5173
  ```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 2. Make Changes

- Follow the existing code structure
- Write clear, self-documenting code
- Add comments for complex logic
- Update tests for changed functionality

### 3. Validate Your Changes

- Ensure the app loads and the service worker updates cleanly
- Test import/export with sample data in `test_data/`
- Verify audio record/playback and the 16-bit WAV capability check

### 4. Commit Changes

Write clear commit messages:
```bash
git add .
git commit -m "feat: add consent screen UI

- Implement verbal consent option
- Add written consent display
- Include consent recording capability"
```

Commit message format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding/updating tests
- `chore:` - Build/config changes

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```
Then open a Pull Request.

## Code Style Guidelines

### Code Style

- Keep it simple and dependency-free when possible
- Use meaningful variable/function names
- Keep functions small and focused
- Prefer progressive enhancement and graceful errors

### File Organization

```
www/
├── index.html
├── css/
├── js/
│   ├── app.js
│   ├── storage.js
│   ├── xml-parser.js
│   ├── audio-recorder.js
│   └── export.js
├── manifest.json
└── service-worker.js
```

### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Widget tree
    );
  }
  
  // Helper methods below build()
  Widget _buildHelper() {
    return Text(data);
  }
}
```

### Testing Guidelines

Manual testing is usually sufficient:
- Import sample XML, verify entries sorted by numeric Reference
- Record a short audio, confirm playback and inclusion in export
- Export ZIP and inspect: UTF-16LE XML, audio files named like `0001body.wav`

## Documentation

### Code Comments

- Add doc comments for public APIs
- Explain "why" not "what" in inline comments
- Keep comments up-to-date

```dart
/// Imports a Dekereke XML wordlist file and stores entries in the database.
///
/// Returns the number of successfully imported entries.
/// Throws [Exception] if the file format is invalid.
Future<int> importDekerekeXml(String filePath) async {
  // Implementation
}
```

### Update README Files

- `README.md` - Main project overview
- `DEVELOPMENT.md` - Developer guide (PWA)
- `www/README.md` - PWA usage notes

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] No syntax errors (check DevTools console)
- [ ] Service worker updates cleanly
- [ ] Documentation updated when needed

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Checklist
- [ ] Tests pass
- [ ] Code analyzed
- [ ] Documentation updated
- [ ] Self-reviewed
```

### Review Process

1. Maintainer will review your PR
2. Address any requested changes
3. Once approved, PR will be merged
4. Your contribution will be credited

### Areas for Contribution

- Consent screen UI (verbal/written)
- LIFT XML export
- Picture support in entries
- i18n and font integration (Charis/Doulos SIL)
- Cloud sync (optional)
- Accessibility and performance

## Architecture Decisions

When making significant changes:

1. **Discuss first** - Open an issue to discuss major changes
2. **Follow patterns** - Use existing architectural patterns
3. **Keep it simple** - Prefer simple, maintainable solutions
4. **Consider users** - Think about fieldwork constraints

### State Management

- Use Provider for app state
- Keep state minimal and localized
- Avoid unnecessary rebuilds

### Data Persistence

- Use IndexedDB for local storage
- Keep schema small and evolvable

### File Operations

- Use path_provider for app directories
- Validate file formats before processing
- Handle errors gracefully

## License Requirements

All contributions must be licensed under **AGPL-3.0** or a compatible license. By contributing, you agree that your contributions will be licensed under AGPL-3.0.

### Important Notes

- The app code is AGPL-3.0
- Wordlist data is CC BY-NC-SA 4.0 (separate license)
- Do not bundle wordlist data in the app

## Getting Help

### Resources

- Project README
- DEVELOPMENT.md (PWA)
- www/README.md

### Questions?

- Open an issue for questions
- Tag with `question` label
- Check existing issues first

### Bug Reports

Please include steps to reproduce, browser and OS, and any console errors.

## Recognition

Contributors will be:
- Listed in the project contributors
- Credited in release notes
- Acknowledged in documentation

Thank you for helping make linguistic fieldwork more accessible! 🌍📱🎙️
