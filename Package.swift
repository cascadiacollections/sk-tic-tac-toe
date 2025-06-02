// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "TicTacToeCore",
            dependencies: [],
            path: "tictactoe Shared",
            exclude: [
                "Actions.sks",
                "Assets.xcassets", 
                "GameScene.sks",
                "GameScene.swift"  // Exclude SpriteKit-dependent files for SPM
            ],
            sources: ["GameLogic.swift"]
        ),
        .testTarget(
            name: "TicTacToeCoreTests",
            dependencies: ["TicTacToeCore"],
            path: "TicTacToeTests",
            sources: ["TicTacToeTests.swift"]
        ),
    ]
)