# GitHub Copilot Instructions for Swift SpriteKit Tic-Tac-Toe

This document provides context and guidelines for GitHub Copilot when working with this Swift SpriteKit project.

## Project Overview

This is a cross-platform Tic-Tac-Toe game built with Swift and SpriteKit, supporting both iOS 17.0+ and macOS 14.0+. The project uses modern Swift features, bitboard optimization, and comprehensive testing.

## Code Style and Conventions

### Swift Style
- Follow Swift API Design Guidelines
- Use SwiftLint for style enforcement (configuration in `.swiftlint.yml`)
- Use `swift-format` for automatic formatting (configuration in `.swift-format`)
- Prefer `let` over `var` for immutable values
- Use explicit types when it improves clarity
- Use trailing closures when appropriate
- Maintain 120 character line limit

### Naming Conventions
- Use descriptive, clear names for all types and methods
- Enum cases should be lowerCamelCase
- Type names should be UpperCamelCase
- Use American English spelling (e.g., "color" not "colour")

### Architecture Patterns
- **GameLogic.swift**: Pure Swift business logic with no UI dependencies
- **GameScene.swift**: SpriteKit scene handling cross-platform UI
- **Platform-specific files**: iOS and macOS specific AppDelegate and GameViewController

## File Structure

```
tictactoe Shared/        # Cross-platform game code
├── GameLogic.swift      # Core game logic with bitboard implementation
├── GameScene.swift      # SpriteKit scene for rendering
├── GameScene.sks        # Scene editor file
└── Assets.xcassets      # Shared assets

tictactoe iOS/           # iOS-specific code
├── AppDelegate.swift
└── GameViewController.swift

tictactoe macOS/         # macOS-specific code
├── AppDelegate.swift
└── GameViewController.swift

TicTacToeTests/          # Unit tests
└── TicTacToeTests.swift
```

## Key Technologies

### SpriteKit
- Used for cross-platform game rendering
- Scene management in `GameScene.swift`
- Touch/click handling for both iOS and macOS

### Swift Testing Framework
- Use `import Testing` for tests
- Prefer `#expect` over XCTest assertions
- Group related tests with `@Test` and `@Suite`
- Use descriptive test names

### Bitboard Implementation
- Game state stored as UInt16 bitmasks for performance
- Bit operations for win detection and move validation
- See `GameLogic.swift` for implementation details

## Development Workflow

### Building
```bash
# Swift Package Manager
swift build

# Xcode iOS
xcodebuild -project tictactoe.xcodeproj -scheme "tictactoe iOS" -destination "platform=iOS Simulator,name=iPhone 15"

# Xcode macOS
xcodebuild -project tictactoe.xcodeproj -scheme "tictactoe macOS" -destination "platform=macOS"

# Or use Makefile
make build-ios
make build-macos
```

### Testing
```bash
# Swift Package Manager
swift test

# Xcode
xcodebuild test -project tictactoe.xcodeproj -scheme "tictactoe iOS" -testPlan "tictactoeTests"

# Or use Makefile
make test-ios
make test-macos
```

### Linting and Formatting
```bash
# Lint code
swiftlint

# Auto-fix linting issues
swiftlint --fix

# Format code
swift-format --in-place --recursive .

# Or use Makefile
make lint
make format
```

## Common Tasks

### Adding a New Feature
1. Add core logic to `GameLogic.swift` (platform-independent)
2. Update UI in `GameScene.swift` (cross-platform)
3. Add platform-specific code if needed in iOS/macOS directories
4. Write tests in `TicTacToeTests/`
5. Run `make check` to validate

### Modifying Game Logic
- Keep `GameLogic.swift` pure Swift (no UIKit/AppKit dependencies)
- Maintain backward compatibility with existing API
- Update tests to cover new behavior
- Consider performance implications for bitboard operations

### UI Changes
- Update `GameScene.swift` for cross-platform changes
- Use `#if os(iOS)` / `#if os(macOS)` for platform-specific code
- Test on both iOS simulator and macOS
- Ensure accessibility is maintained

### Adding Dependencies
1. Update `Package.swift` for SPM dependencies
2. Update `.github/dependabot.yml` to monitor new dependencies
3. Document why the dependency is needed
4. Prefer Swift-native solutions when possible

## Testing Guidelines

### Unit Tests
- Test all public APIs in `GameLogic.swift`
- Use descriptive test names that explain what is being tested
- Test edge cases and error conditions
- Maintain high code coverage (aim for >80%)

### Test Organization
```swift
@Suite("Game Logic Tests")
struct GameLogicTests {
    @Test("Making a valid move")
    func testValidMove() {
        // Test implementation
    }
    
    @Test("Detecting a win condition")
    func testWinDetection() {
        // Test implementation
    }
}
```

## CI/CD Integration

### GitHub Actions Workflows
- **ci.yml**: Multi-platform builds, tests, and coverage
- **security.yml**: CodeQL analysis and security scanning

### Pre-commit Checks
The DevContainer includes Git hooks for:
- SwiftLint validation
- Code formatting checks
- Basic compilation tests

## Platform Considerations

### iOS Specifics
- Minimum deployment: iOS 17.0
- Touch-based input handling
- Portrait and landscape orientations
- Support for various screen sizes

### macOS Specifics
- Minimum deployment: macOS 14.0
- Mouse and keyboard input
- Window resizing support
- Menu bar integration

### Cross-Platform Code
- Use SpriteKit's cross-platform APIs
- Abstract platform differences in GameViewController
- Share assets and logic in `tictactoe Shared/`

## Performance Optimization

### Bitboard Operations
- Game state uses UInt16 for compact representation
- Win detection uses pre-computed patterns
- Move validation is O(1) time complexity

### Memory Management
- Prefer value types (structs) over reference types (classes)
- Use `weak` and `unowned` to prevent retain cycles
- Profile with Instruments for memory leaks

## Documentation

### Code Comments
- Document public APIs with `///` documentation comments
- Use `// MARK:` to organize code sections
- Explain complex algorithms and bitboard operations
- Document platform-specific workarounds

### README Updates
- Keep README.md current with project capabilities
- Update when adding new features or changing requirements
- Include code examples for common use cases

## Security Best Practices

- No sensitive data in source code
- No hardcoded credentials or API keys
- Use environment variables for configuration
- Follow Swift security best practices

## Accessibility

- Ensure all UI elements have accessibility labels
- Support VoiceOver on iOS
- Support VoiceOver on macOS
- Test with accessibility features enabled

## Common Pitfalls to Avoid

1. **Don't mix UIKit/AppKit in shared code**: Keep platform-specific code in iOS/macOS directories
2. **Don't ignore SwiftLint warnings**: Fix them or document why they should be ignored
3. **Don't skip tests**: Every public API should have test coverage
4. **Don't hardcode values**: Use constants and configuration
5. **Don't break backward compatibility**: Consider API evolution carefully

## Helpful Commands

```bash
# Development workflow
make dev              # Format, lint, and test
make check            # Run all quality checks
make ci               # Simulate CI environment

# Building specific targets
make ios              # Build and test iOS
make macos            # Build and test macOS
make all              # Build and test everything

# Performance
make benchmark        # Run performance benchmarks

# Cleanup
make clean            # Clean build artifacts
make reset            # Reset development environment
```

## Additional Resources

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SpriteKit Programming Guide](https://developer.apple.com/documentation/spritekit)
- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)

## Questions or Issues?

- Check existing issues and pull requests
- Review CONTRIBUTING.md for contribution guidelines
- Ensure all tests pass before submitting PRs
- Follow the pull request template
