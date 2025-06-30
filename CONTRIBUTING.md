# Contributing to SK-Tic-Tac-Toe

Thank you for considering contributing to this project! Here are some guidelines to help you get started.

## Development Environment

This project uses Swift and SpriteKit for iOS and macOS development with modern tooling and practices.

### Prerequisites
- **Xcode 15.0 or higher** (for iOS/macOS development)
- **Swift 5.9 or higher**
- **macOS 13.0 or higher**

### Development Environment Setup

#### Option 1: Xcode Development
1. Clone the repository
2. Open `tictactoe.xcodeproj` in Xcode
3. Build and run the project (⌘+R)

#### Option 2: VS Code with DevContainer
1. Install VS Code and the DevContainer extension
2. Install Docker Desktop
3. Open the repository in VS Code
4. When prompted, choose "Reopen in Container"
5. The environment will automatically set up with all required tools

#### Option 3: Manual Setup
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