# Contributing to CarbonTracker

⭐ First off, thank you for considering contributing to this project! ⭐

We welcome contributions from everyone. By participating in this project, you agree to abide by our Code of Conduct.

## 🚨 IMPORTANT: Discord Communication is Mandatory

**All project communication MUST happen on Discord. We do not pay attention to GitHub notifications.**

- Join our [Discord server](https://discord.gg/hjUhu33uAn) before starting any work
- Use the [CarbonTracker project channel](https://discord.com/channels/1022871757289422898/1500961382831755264) for all project-specific discussion
- Post your PR/issue updates in the relevant Discord channel (**MANDATORY**)
- All discussions, questions, and updates should be on Discord
- GitHub is for code only - Discord is for communication

**PRs without Discord updates will not be reviewed or may face delays.**

## 📋 Table of Contents

- [How Can I Contribute?](#how-can-i-contribute)
- [Coding with AI](#coding-with-ai)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Code Style Guidelines](#code-style-guidelines)
- [Community Guidelines](#community-guidelines)

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- Clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Screenshots/Video (if applicable)
- Environment details (OS, device/emulator, Flutter version, etc.)

### Suggesting Features

Feature suggestions are welcome! Please:

- Check if the feature has already been suggested
- Provide a clear description of the feature
- Explain why this feature would be useful
- Include examples of how it would work

### Contributing Code

1. **Submit an Issue First**: For features, bugs, or enhancements, create an issue first
2. **Get Assigned**: Wait to be assigned before starting work (preferable)
3. **Submit Your PR**: Once assigned, create a PR addressing the issue
4. **Unrelated PRs**: Pull requests unrelated to issues may be closed or take longer to review

## 🤖 Coding with AI

We accept the use of AI-powered tools (GitHub Copilot, ChatGPT, Claude, Cursor, etc.) for contributions, whether for code, tests, or documentation.

⚠️ However, transparency is required: if you use AI assistance, please mention it in your PR description. This helps maintainers during code review and ensure the quality of contributions.

What we expect:
- **Disclose AI usage**: A simple note like "Used GitHub Copilot for autocompletion" or "Generated initial test structure with ChatGPT" is sufficient.
- **Specify the scope**: Indicate which parts of your contribution involved AI assistance.
- **Review AI-generated content**: Ensure you understand and have verified any AI-generated code before submitting.

## 🚀 Getting Started

### Prerequisites

Before setting up CarbonTracker, make sure you have the following installed:

- Flutter
- Dart (included with Flutter)
- Android Studio or another Flutter-supported development environment
- An Android/iOS emulator or a physical device

You can verify your Flutter installation by running:

```bash
flutter doctor
```

Resolve any issues reported by `flutter doctor` before proceeding.

### Setup

1. **Fork the Repository**
   ```bash
   # Click the 'Fork' button at the top right of this page
   ```

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/AOSSIE-Org/CarbonTracker.git
   cd CarbonTracker
   ```

3. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/AOSSIE-Org/CarbonTracker.git
   ```

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the Project**
   ```bash
   flutter run
   ```

## 🔄 Development Workflow

### 1. Create a Feature Branch

Always work on a new branch, never on `main` or `dev`:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write clean, readable code
- Follow the project's code style
- Add comments where necessary
- Update documentation if needed

### 3. Test Your Changes

```bash
flutter test
# or
flutter analyze
```

### 4. Commit Your Changes

Write clear, concise commit messages:

```bash
git add .
git commit -m "feat: add user authentication"
# or
git commit -m "fix: resolve navigation bug"
```

**Commit Message Format:**
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests
- `chore:` for maintenance tasks

### 5. Keep Your Branch Updated

```bash
git fetch upstream
git rebase upstream/main
# or upstream/dev depending on the project
```

### 6. Push Your Changes

```bash
git push origin feature/your-feature-name
```

## 📤 Pull Request Guidelines

### Before Submitting

- [ ] Your code follows the project's style guidelines
- [ ] You've tested your changes thoroughly
- [ ] You've updated relevant documentation
- [ ] Your commits are clean and well-organized
- [ ] You've rebased with the latest upstream changes
- [ ] You've thought from the reviewer's perspective and made your PR easy to review

### Submitting a Pull Request

1. Go to the original repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill out the PR template with:
    - Clear description of changes
    - Link to related issue(s)
    - Screenshots (if UI changes)
    - Testing steps

### PR Description Template

```markdown
## Description
Brief description of what this PR does

## Related Issue
Closes #issue_number

## Screenshots/Video (if applicable)
Add screenshots here

## Testing (if applicable)
Steps to test the changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### After Submission

- Post your PR in the [CarbonTracker Discord channel](https://discord.com/channels/1022871757289422898/1500961382831755264) for visibility (**IMPORTANT**)
- Respond to review comments promptly
- Make requested changes in new commits
- Be patient - maintainers will review when available
- Use `[WIP]` in your PR title for incomplete PRs. Don't use this as a way to gatekeep; focus on one change until it gets merged.

### Reviewing PRs

- Instead of opening duplicate PRs, help review and improve existing ones.
- When reviewing, assess whether the change is actually necessary before diving into implementation details and functionality testing.

## 📝 Code Style Guidelines

CarbonTracker follows standard Dart and Flutter conventions.

### General Guidelines

- Use meaningful variable, function, and class names
- Keep widgets and functions small and focused
- Add comments for complex logic
- Remove `print`/debug statements before committing
- Avoid code duplication
- Avoid unnecessary complexity and premature optimization

### Dart & Flutter

- Follow the [Effective Dart](https://dart.dev/effective-dart) style guide
- Format your code with `dart format` before committing:
  ```bash
  dart format .
  ```
- Run static analysis and fix any issues before opening a PR:
  ```bash
  flutter analyze
  ```
- This project uses [`flutter_lints`](https://pub.dev/packages/flutter_lints) for linting, make sure your changes don't introduce new lint warnings
- Prefer `const` constructors where possible for widgets that don't change
- Use `final` for variables that aren't reassigned
- Follow the existing feature-based folder structure when adding new files
- Use Riverpod conventions consistent with the rest of the codebase for state management
- Keep widget build methods readable. Extract complex widgets into their own private widgets or methods when a `build()` method grows too large

## 🌟 Community Guidelines

### Communication

- Be respectful and inclusive
- Provide constructive feedback
- Help others when you can
- Ask questions - no question is too small!

### Progress Updates

- If your work is taking longer than expected, comment on Discord with updates
- Issues should be completed within 5-30 days depending on complexity
- If you can no longer work on an issue, let maintainers know on Discord

### Getting Help

- Check existing documentation first
- Search closed issues for similar problems
- Ask in Discord
- Tag maintainers if your PR is unattended for 1-2 weeks on Discord

## 🎯 Issue Assignment

- One contributor per issue (unless specified otherwise)
<!--
- Wait for assignment before starting work
- Issues will be reassigned if inactive for extended periods
-->
- If there are no active PRs for an issue for 2+ days, mention your intent under the issue and begin
- Avoid working on issues which are assigned to someone, even if they are inactive
- Check for existing PRs before starting to avoid duplication, as there might be PRs that didn't mention the related issue

Thank you for contributing to CarbonTracker! Your efforts help make this project better for everyone. 🚀
