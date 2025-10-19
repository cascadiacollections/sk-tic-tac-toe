# Contributing to SK-Tic-Tac-Toe

Thank you for considering contributing to this project! Here are some guidelines to help you get started.

## Development Environment

This project uses Swift and SpriteKit for iOS and macOS development with modern tooling and practices.

### Prerequisites
- **Xcode 15.0 or higher** (for iOS/macOS development)
- **Swift 5.9 or higher**
- **macOS 13.0 or higher**

### Development Environment Setup

#### Option 1: GitHub Codespaces (Recommended for Quick Start)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/cascadiacollections/sk-tic-tac-toe?quickstart=1)

1. Click the badge above or navigate to the repository
2. Click "Code" → "Create codespace on main"
3. Wait for the environment to build (~2-3 minutes first time)
4. Start coding with all tools pre-configured!

**Advantages:**
- No local setup required
- Consistent environment for all contributors
- GitHub Copilot enabled by default
- Pre-installed tools (SwiftLint, swift-format, etc.)
- Cloud-based development from any machine

#### Option 2: Xcode Development
1. Clone the repository
2. Open `tictactoe.xcodeproj` in Xcode
3. Build and run the project (⌘+R)

#### Option 3: VS Code with DevContainer
1. Install VS Code and the DevContainer extension
2. Install Docker Desktop
3. Open the repository in VS Code
4. When prompted, choose "Reopen in Container"
5. The environment will automatically set up with all required tools

#### Option 4: Manual Setup
```bash
# Install SwiftLint
brew install swiftlint

# Install swift-format
git clone https://github.com/apple/swift-format.git
cd swift-format
swift build -c release
sudo cp .build/release/swift-format /usr/local/bin/
```

### 🔧 Development Tools

The project includes several tools to maintain code quality:

- **SwiftLint**: Style and convention enforcement
- **swift-format**: Automatic code formatting  
- **Pre-commit hooks**: Automated quality checks
- **Git hooks**: Prevent commits that don't meet quality standards
- **GitHub Copilot**: AI-powered code assistance (see `.github/copilot-instructions.md`)

#### Using GitHub Copilot

GitHub Copilot is pre-configured and optimized for this project:

- **Copilot Instructions**: Comprehensive project context in `.github/copilot-instructions.md`
- **Smart Suggestions**: Understands Swift patterns, SpriteKit APIs, and bitboard operations
- **Test Generation**: Great for writing test cases - just describe what you want to test
- **Documentation Help**: Ask Copilot Chat to explain complex code sections

**Best Practices:**
- Write clear comments to guide Copilot's suggestions
- Use descriptive variable and function names
- Review all Copilot suggestions before accepting
- Copilot is a tool to assist, not replace thoughtful coding

### 🧪 Testing Strategy

We use comprehensive testing approaches:

- **Unit Tests**: Swift Testing framework for core logic
- **Integration Tests**: Cross-platform compatibility testing
- **UI Tests**: Platform-specific interface testing (when applicable)
- **Performance Tests**: Bitboard operation benchmarks

### 📱 Platform Testing

Test on multiple platforms and configurations:

- **iOS**: iPhone and iPad simulators + physical devices
- **macOS**: Intel and Apple Silicon Macs
- **Multiple OS versions**: Latest and previous major versions

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style Guidelines

We follow strict code quality standards:

#### Swift Style
- Follow [Swift's API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift's standard library types where applicable
- Prefer `let` over `var` when possible
- Use meaningful, descriptive names for variables and functions
- Avoid force unwrapping (`!`) unless absolutely necessary and well-documented

#### Code Organization
- Group related functionality using `// MARK: -` comments
- Keep functions focused and under 60 lines when possible
- Use extensions to organize protocol conformances
- Maintain consistent indentation (4 spaces)

#### Error Handling
- Use proper Swift error handling with `do-catch` blocks
- Create custom error types when appropriate
- Provide meaningful error messages

#### Documentation
- Document public APIs with Swift documentation comments (`///`)
- Include usage examples for complex functions
- Keep comments up-to-date with code changes

### 🔍 Code Quality Checks

Before submitting code, ensure it passes all quality checks:

```bash
# Run SwiftLint
swiftlint

# Format code
swift-format --in-place --recursive .

# Run tests
swift test  # or ⌘+U in Xcode

# Verify build on both platforms
xcodebuild build -scheme "tictactoe iOS" -destination "platform=iOS Simulator,name=iPhone 15"
xcodebuild build -scheme "tictactoe macOS" -destination "platform=macOS"
```

## Testing

Comprehensive testing is required for all contributions:

### Running Tests

```bash
# Swift Package Manager
swift test

# Xcode (⌘+U)
# Or via command line:
xcodebuild test -scheme "tictactoe iOS" -destination "platform=iOS Simulator,name=iPhone 15" -testPlan "tictactoeTests"
```

### Test Requirements

- **Unit tests** for all new game logic
- **Integration tests** for cross-platform compatibility  
- **Performance tests** for any algorithm changes
- **Error case testing** for all error paths
- **Edge case coverage** (board boundaries, invalid moves, etc.)

### Test Guidelines

- Use descriptive test names that explain what is being tested
- Follow the Arrange-Act-Assert pattern
- Test both success and failure cases
- Use the Swift Testing framework (`@Test`, `#expect`)
- Mock dependencies when appropriate
- Aim for high code coverage (>90% for core logic)

### Before Submitting

Make sure all tests pass:
- [ ] Unit tests pass locally
- [ ] Integration tests pass on both platforms
- [ ] Performance tests show no regression
- [ ] CI pipeline passes (GitHub Actions)
- [ ] Code coverage meets standards

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license.