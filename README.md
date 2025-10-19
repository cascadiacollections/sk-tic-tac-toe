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

### ☁️ Instant Development with GitHub Codespaces

Get started in seconds with a fully configured cloud development environment:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/cascadiacollections/sk-tic-tac-toe?quickstart=1)

**What you get:**
- Pre-configured Swift 5.10+ environment
- GitHub Copilot integration for AI-assisted coding
- All development tools pre-installed (SwiftLint, swift-format)
- Git hooks configured automatically
- No local setup required!

**Getting Started:**
1. Click the badge above or go to the repository and click "Code" → "Create codespace on main"
2. Wait for the environment to build (first time takes ~2-3 minutes, subsequent launches are faster)
3. Start coding immediately with `make dev`

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
   - GitHub Copilot integration

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

### 🤖 GitHub Copilot Integration

This project is optimized for GitHub Copilot with comprehensive instructions in `.github/copilot-instructions.md`:

- **Smart Code Suggestions**: Copilot understands the project's Swift style, SpriteKit patterns, and bitboard implementation
- **Context-Aware**: Knows about cross-platform requirements (iOS/macOS) and testing conventions
- **Best Practices**: Suggests code following SwiftLint rules and project conventions
- **Enabled by Default**: Pre-configured in DevContainer and Codespaces

**Tips for using Copilot:**
- Write descriptive comments before functions to get better suggestions
- Use descriptive variable/function names for context
- Copilot works great for tests - describe what you want to test in a comment
- Ask Copilot Chat for explanations of bitboard operations or SpriteKit APIs

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

### ⚡ Performance Benchmarking

Run performance benchmarks to analyze game logic efficiency:

```bash
# Run performance benchmarks
make benchmark

# Or run directly
swift scripts/benchmark.swift
```

The benchmarks test:
- Game logic initialization performance
- Move making efficiency
- Large board scaling
- Reset operation speed

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
- **Automated Updates**: Dependabot for dependency management

### 🔄 Dependency Management

Dependencies are automatically monitored and updated via Dependabot:

- **GitHub Actions**: Weekly updates for workflow dependencies
- **Swift Packages**: Weekly updates for any external Swift dependencies  
- **Docker**: Weekly updates for DevContainer base images
- **Security**: Automatic security updates and vulnerability scanning

## Contributing

Contributions are welcome! Please see the [Contributing Guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
