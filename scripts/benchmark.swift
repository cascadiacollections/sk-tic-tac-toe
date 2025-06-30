#!/usr/bin/env swift

import Foundation

// Simple performance benchmark script for TicTacToe
func measureTime<T>(_ operation: () throws -> T) rethrows -> (result: T, timeInSeconds: Double) {
    let startTime = DispatchTime.now()
    let result = try operation()
    let endTime = DispatchTime.now()
    let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let timeInSeconds = Double(nanoTime) / 1_000_000_000
    return (result, timeInSeconds)
}

// Mock GameLogic for the benchmark script (simplified version)
class GameLogic {
    let boardSize: Int
    private var board: [[Int?]]
    private var currentPlayer = 1 // 1 for X, 2 for O
    
    init?(boardSize: Int) {
        guard boardSize >= 1 else { return nil }
        self.boardSize = boardSize
        self.board = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
    }
    
    func makeMove(row: Int, col: Int) -> Bool {
        guard row >= 0 && row < boardSize && col >= 0 && col < boardSize else { return false }
        guard board[row][col] == nil else { return false }
        
        board[row][col] = currentPlayer
        currentPlayer = currentPlayer == 1 ? 2 : 1
        return true
    }
    
    func reset() {
        board = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        currentPlayer = 1
    }
}

print("🚀 TicTacToe Performance Benchmark")
print(String(repeating: "=", count: 50))

// Test 1: Initialization Performance
print("\n📋 Test 1: Initialization Performance")
let initIterations = 10_000
let (_, initTime) = measureTime {
    for _ in 0..<initIterations {
        _ = GameLogic(boardSize: 3)
    }
}
let avgInitTime = initTime / Double(initIterations) * 1_000_000
print("   ✅ \(initIterations) initializations: \(String(format: "%.2f", avgInitTime)) μs per init")

// Test 2: Move Making Performance
print("\n🎯 Test 2: Move Making Performance")
guard let logic = GameLogic(boardSize: 3) else {
    print("   ❌ Failed to initialize GameLogic")
    exit(1)
}

let moveIterations = 10_000
let (_, moveTime) = measureTime {
    for i in 0..<moveIterations {
        let row = i % 3
        let col = (i / 3) % 3
        _ = logic.makeMove(row: row, col: col)
        
        if i % 9 == 8 {
            logic.reset()
        }
    }
}
let avgMoveTime = moveTime / Double(moveIterations) * 1_000_000
print("   ✅ \(moveIterations) moves: \(String(format: "%.2f", avgMoveTime)) μs per move")

// Test 3: Large Board Performance
print("\n📏 Test 3: Large Board Performance")
for size in [5, 8, 10] {
    guard let largeLogic = GameLogic(boardSize: size) else {
        print("   ❌ Failed to initialize \(size)x\(size) board")
        continue
    }
    
    let (_, largeTime) = measureTime {
        for i in 0..<min(50, size * size) {
            let row = i % size
            let col = (i / size) % size
            _ = largeLogic.makeMove(row: row, col: col)
        }
    }
    print("   ✅ \(size)x\(size) board (50 moves): \(String(format: "%.2f", largeTime * 1000)) ms")
}

// Test 4: Reset Performance
print("\n🔄 Test 4: Reset Performance")
let resetIterations = 10_000
let (_, resetTime) = measureTime {
    for _ in 0..<resetIterations {
        logic.reset()
    }
}
let avgResetTime = resetTime / Double(resetIterations) * 1_000_000
print("   ✅ \(resetIterations) resets: \(String(format: "%.2f", avgResetTime)) μs per reset")

print("\n" + String(repeating: "=", count: 50))
print("✅ Performance benchmark completed!")
print("📊 Summary:")
print("   • Initialization: \(String(format: "%.2f", avgInitTime)) μs")
print("   • Move making: \(String(format: "%.2f", avgMoveTime)) μs")
print("   • Reset operation: \(String(format: "%.2f", avgResetTime)) μs")