# Contributing to Wordlist Elicitation Tool

Thank you for your interest in contributing to this project! This Flutter implementation aims to provide a simple, accessible tool for linguistic fieldwork.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment for all contributors

## Getting Started

### Prerequisites

1. **Flutter SDK** - Install from https://flutter.dev/docs/get-started/install
2. **Git** - For version control
3. **IDE** - Android Studio or VS Code with Flutter extensions
4. **Android SDK** - For building Android apps

### Setup Development Environment

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Quickstart_Android.git
   cd Quickstart_Android
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Verify setup:
   ```bash
   flutter doctor
   flutter analyze
   flutter test
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

### 3. Test Your Changes

```bash
# Run all tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Run the app
flutter run
```

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

Then create a Pull Request on GitHub.

## Code Style Guidelines

### Dart/Flutter Conventions

1. **Follow Dart style guide**: https://dart.dev/guides/language/effective-dart/style
2. **Use `flutter format`** before committing
3. **Prefer `const` constructors** where possible
4. **Use meaningful variable names**

Example:
```dart
// Good
final wordlistEntry = WordlistEntry(
  id: 1,
  reference: '0001',
  gloss: 'body',
);

// Avoid
final we = WordlistEntry(
  id: 1,
  reference: '0001',
  gloss: 'body',
);
```

### File Organization

```
lib/
├── models/          # Data models only
├── services/        # Business logic, external APIs
├── providers/       # State management
├── screens/         # Full-page UI components
├── widgets/         # Reusable UI components
└── utils/           # Helper functions, constants
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

## Testing Guidelines

### Unit Tests

Write unit tests for:
- Models (serialization, validation)
- Services (business logic)
- Utilities

Example:
```dart
test('should create WordlistEntry from map', () {
  final map = {'id': 1, 'reference': '0001', 'gloss': 'body'};
  final entry = WordlistEntry.fromMap(map);
  expect(entry.id, 1);
});
```

### Widget Tests

Test UI components:
```dart
testWidgets('displays word gloss', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: WordCard(gloss: 'body')),
  );
  expect(find.text('body'), findsOneWidget);
});
```

### Integration Tests

For complex workflows (optional but recommended).

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

- `README.md` - Main project goals (already exists)
- `FLUTTER_README.md` - Flutter-specific documentation
- `DEVELOPMENT.md` - Development guide

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] All tests pass (`flutter test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Code is formatted (`flutter format .`)
- [ ] Documentation is updated
- [ ] Commits are clean and meaningful

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

## Areas for Contribution

### High Priority

1. **Consent Screen UI** - Implement verbal/written consent options
2. **LIFT XML Export** - Add LIFT format support
3. **Image Display** - Show pictures from wordlist data
4. **Error Handling** - Improve error messages and recovery

### Medium Priority

5. **Font Integration** - Add Charis SIL, Doulos SIL fonts
6. **Keyboard Support** - Better IPA input handling
7. **Cloud Sync** - Optional data backup
8. **Data Validation** - Input validation and quality checks

### Future Enhancements

9. **Desktop Support** - Windows/Mac/Linux versions
10. **Web Version** - Browser-based tool
11. **Advanced Audio** - Audio editing features
12. **Batch Operations** - Bulk import/export

### Documentation

- Improve setup instructions
- Add video tutorials
- Create user guide
- Translate documentation

### Testing

- Increase test coverage
- Add integration tests
- Performance testing
- Accessibility testing

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

- Use SQLite (via sqflite) for local storage
- Follow database service pattern
- Handle migrations carefully

### File Operations

- Use path_provider for app directories
- Validate file formats before processing
- Handle errors gracefully

## License Requirements

All contributions must be licensed under **AGPL-3.0** or a compatible license.

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 license.

### Important Notes

- The app code is AGPL-3.0
- Wordlist data is CC BY-NC-SA 4.0 (separate license)
- Do not bundle wordlist data in the app

## Getting Help

### Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Project README**: See main README.md for project goals
- **Development Guide**: See DEVELOPMENT.md

### Questions?

- Open an issue for questions
- Tag with `question` label
- Check existing issues first

### Bug Reports

Use this template:

```markdown
## Bug Description
What went wrong?

## Steps to Reproduce
1. Step 1
2. Step 2

## Expected Behavior
What should happen?

## Actual Behavior
What actually happened?

## Environment
- Flutter version:
- Device/Emulator:
- Android version:

## Screenshots
If applicable
```

## Recognition

Contributors will be:
- Listed in the project contributors
- Credited in release notes
- Acknowledged in documentation

Thank you for helping make linguistic fieldwork more accessible! 🌍📱🎙️
