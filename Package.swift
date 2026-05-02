// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TicTacToe",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TicTacToeCore",
            targets: ["TicTacToeCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TicTacToeCore",
            dependencies: [],
            path: "tictactoe Shared",
            exclude: [
                "Assets.xcassets",
                "GameScene.swift",
                "MainMenuScene.swift"
            ],
            sources: [
                "GameLogic.swift",
                "GamePersistence.swift"
            ]
        ),
        .testTarget(
            name: "TicTacToeCoreTests",
            dependencies: ["TicTacToeCore"],
            path: "TicTacToeTests",
            sources: ["TicTacToeTests.swift"]
        ),
    ]
)
