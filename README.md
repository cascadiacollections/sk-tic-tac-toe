# Swift SpriteKit Tic-Tac-Toe

[![CI](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/ci.yml/badge.svg)](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/ci.yml)
[![Security](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/security.yml/badge.svg)](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/security.yml)
[![CodeQL](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/security.yml/badge.svg?event=schedule)](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/security.yml)
[![SwiftLint](https://img.shields.io/badge/SwiftLint-enabled-brightgreen.svg)](https://github.com/realm/SwiftLint)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017.0+%20|%20macOS%2014.0+-blue.svg)](https://developer.apple.com)

A modern Tic-Tac-Toe game implemented using Swift and SpriteKit, supporting both iOS and macOS platforms with comprehensive CI/CD, development tooling, and modern Swift practices.

## Features

- Cross-platform (iOS and macOS) support through SpriteKit
- Efficient game logic using bitboards for fast performance
- Modern Swift API design with proper error handling
- Comprehensive unit tests with the Swift Testing framework
- Type-safe game state management
- Responsive UI that adapts to different screen sizes
- Accessibility support built-in

## Requirements

- **Development:** Xcode 15.0+ or VS Code with DevContainer
- **Swift:** 5.9 or later
- **Platforms:** iOS 17.0+ / macOS 14.0+
- **Optional:** Swift Package Manager for library usage

## Getting Started

### 🚀 Quick Start with Xcode

1. **Clone the repository**
```bash
git clone https://github.com/cascadiacollections/sk-tic-tac-toe.git
cd sk-tic-tac-toe
```

2. **Open in Xcode**
```bash
open tictactoe.xcodeproj
```

3. **Build and run** on your preferred device or simulator (⌘+R)

### 🐳 Development with VS Code and DevContainer

This project includes a complete DevContainer setup for VS Code development:

1. **Prerequisites:**
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. **Open in DevContainer:**
   ```bash
   code .
   # When prompted, click "Reopen in Container"
   ```

3. **Start developing** with a pre-configured environment including:
   - Swift 5.10+ 
   - SwiftLint and swift-format
   - Git hooks for code quality
   - VS Code extensions for Swift development

### 📦 Swift Package Manager

You can also use the core game logic as a Swift package:

```swift
// In your Package.swift
dependencies: [
    .package(url: "https://github.com/cascadiacollections/sk-tic-tac-toe.git", from: "1.0.0")
]
```

```swift
// In your Swift code
import TicTacToeCore

let game = GameLogic(boardSize: 3)
let result = game.makeMove(row: 0, col: 0)
```

## Project Structure

- `tictactoe Shared/`: Common code for both platforms
  - `GameLogic.swift`: Core game logic implementation with bitboard optimization
  - `GameScene.swift`: SpriteKit scene implementation with cross-platform support
- `tictactoe iOS/`: iOS-specific code and configurations
- `tictactoe macOS/`: macOS-specific code and configurations  
- `TicTacToeTests/`: Comprehensive unit tests using Swift Testing
- `Package.swift`: Swift Package Manager configuration for library usage
- `.github/`: CI/CD workflows and issue templates
- `.devcontainer/`: VS Code DevContainer configuration

## Development

### 🛠️ Build Tools

The project includes modern development tooling:

- **SwiftLint**: Enforces Swift style and conventions
- **swift-format**: Automatic code formatting
- **Pre-commit hooks**: Automated quality checks
- **GitHub Actions**: CI/CD with multi-platform testing
- **CodeQL**: Security and quality analysis

### 🧪 Testing

Run tests using multiple methods:

```bash
# Xcode
⌘+U in Xcode

# Swift Package Manager
swift test

# Command line with xcodebuild
xcodebuild test -scheme "tictactoe iOS" -destination "platform=iOS Simulator,name=iPhone 15"
```

### 🔍 Code Quality

Maintain code quality with the included tools:

```bash
# Lint your code
swiftlint

# Format your code  
swift-format --in-place --recursive .

# Run all quality checks (via pre-commit hook)
.git/hooks/pre-commit
```

### 🚀 CI/CD

The project includes comprehensive GitHub Actions workflows:

- **CI Pipeline**: Multi-platform builds, testing, and code coverage
- **Security Scanning**: CodeQL analysis and dependency review
- **Quality Gates**: SwiftLint validation and formatting checks
- **Matrix Testing**: Multiple Xcode and Swift versions

## Contributing

Contributions are welcome! Please see the [Contributing Guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
