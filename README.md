# Swift SpriteKit Tic-Tac-Toe

[![Xcode - Build and Test](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/xcode.yml/badge.svg)](https://github.com/cascadiacollections/sk-tic-tac-toe/actions/workflows/xcode.yml)

A modern Tic-Tac-Toe game implemented using Swift and SpriteKit, supporting both iOS and macOS platforms.

## Features

- Cross-platform (iOS and macOS) support through SpriteKit
- Efficient game logic using bitboards
- Modern Swift API design
- Unit tests with the Swift Testing framework

## Requirements

- Xcode 15.0 or later
- Swift 5.9 or later
- iOS 17.0+ / macOS 14.0+

## Getting Started

### Installation

1. Clone this repository
```bash
git clone https://github.com/cascadiacollections/sk-tic-tac-toe.git
cd sk-tic-tac-toe
```

2. Open the Xcode project
```bash
open tictactoe.xcodeproj
```

3. Build and run the application on your preferred device or simulator

### Development with VS Code and DevContainer

This project supports development in VS Code using DevContainers:

1. Install [VS Code](https://code.visualstudio.com/) and the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open this repository in VS Code
3. When prompted, click "Reopen in Container"

## Project Structure

- `tictactoe Shared/`: Common code for both platforms
  - `GameLogic.swift`: Core game logic implementation
  - `GameScene.swift`: SpriteKit scene implementation
- `tictactoe iOS/`: iOS-specific code
- `tictactoe macOS/`: macOS-specific code
- `TicTacToeTests/`: Unit tests

## Contributing

Contributions are welcome! Please see the [Contributing Guidelines](CONTRIBUTING.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
