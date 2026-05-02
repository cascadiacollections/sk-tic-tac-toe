//
//  GameLogic.swift
//  tictactoe Shared
//
//  Created by Kevin T. Coughlin on 10/29/24.
//

import Foundation
import os

// MARK: - Player

public enum Player: Int, CaseIterable, Sendable, Codable {
    case x = 1, o
    public var symbol: String { rawValue == 1 ? "❌" : "⭕" }
    public var next: Player { self == .x ? .o : .x }
}

// MARK: - GameState

public enum GameState: Equatable, Sendable, Codable {
    case ongoing
    case won(Player)
    case draw
}

// MARK: - GameSnapshot

/// A serializable snapshot of a `GameLogic` instance — sufficient to
/// reconstruct the full logical state (board, current player, game state,
/// and undo history).
public struct GameSnapshot: Codable, Sendable, Equatable {
    public let boardSize: Int
    /// Bitboard for X pieces, stored as `UInt64` for portable serialization.
    public let xBoard: UInt64
    /// Bitboard for O pieces, stored as `UInt64` for portable serialization.
    public let oBoard: UInt64
    public let currentPlayer: Player
    public let gameState: GameState
    public let moveHistory: [MoveRecord]

    public init(
        boardSize: Int,
        xBoard: UInt64,
        oBoard: UInt64,
        currentPlayer: Player,
        gameState: GameState,
        moveHistory: [MoveRecord] = []
    ) {
        self.boardSize = boardSize
        self.xBoard = xBoard
        self.oBoard = oBoard
        self.currentPlayer = currentPlayer
        self.gameState = gameState
        self.moveHistory = moveHistory
    }
}

// MARK: - MoveRecord

/// A completed move, in the order it was played.
public struct MoveRecord: Codable, Sendable, Equatable {
    public let row: Int
    public let col: Int
    public let player: Player

    public init(row: Int, col: Int, player: Player) {
        self.row = row
        self.col = col
        self.player = player
    }
}

// MARK: - MoveOutcome

public enum MoveOutcome: Equatable, Sendable {
    case success
    case failurePositionTaken
    case failureInvalidCoordinates
    case failureGameAlreadyOver
}

// MARK: - GameLogic

/// Encapsulates the logic for a Tic Tac Toe game on an NxN board.
///
/// All methods are main-actor isolated; use from UI code directly
/// or call from `await MainActor.run { }` in concurrent contexts.
@MainActor
public final class GameLogic {

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "GameLogic"
    )

    // MARK: - Public State

    /// The size of the board (NxN).
    public let boardSize: Int

    /// The player whose turn it is.
    public private(set) var currentPlayer: Player = .x

    /// The current state of the game.
    public private(set) var gameState: GameState = .ongoing

    // MARK: - Private State

    private var xBoard = 0
    private var oBoard = 0
    private var winningPattern: Int?
    private let fullBoardMask: Int
    private var moveHistory: [MoveRecord] = []

    /// Winning-pattern cache shared across all instances.
    /// Populated once per board size; never mutated after insertion.
    /// Safe because the class (and thus this static) is `@MainActor`-isolated.
    private static var cachedWinningPatterns: [Int: [Int]] = [:]

    // MARK: - Init

    /// Creates a new game logic instance for a board of the specified size.
    /// - Parameter boardSize: Size of the board (NxN). Must be at least 1 and at most 7
    ///   (boards larger than 7×7 exceed the 64-bit integer used for bitboard storage).
    /// - Returns: `nil` if `boardSize` is out of range.
    public init?(boardSize: Int = 3) {
        guard boardSize >= 1, boardSize * boardSize < Int.bitWidth else {
            Self.log.error("Initialization failed: boardSize \(boardSize) out of range 1…7")
            return nil
        }
        self.boardSize = boardSize
        self.fullBoardMask = (1 << (boardSize * boardSize)) &- 1
        if GameLogic.cachedWinningPatterns[boardSize] == nil {
            Self.log.debug("Generating winning patterns for board size \(boardSize)")
            GameLogic.cachedWinningPatterns[boardSize] = GameLogic.generateWinningPatterns(boardSize: boardSize)
        }
        Self.log.info("GameLogic init boardSize=\(boardSize) first=\(Player.x.symbol)")
    }

    // MARK: - Public API

    /// Attempts to make a move at the specified coordinates.
    /// - Returns: `MoveOutcome` indicating success or the reason for failure.
    @discardableResult
    public func makeMove(row: Int, col: Int) -> MoveOutcome {
        Self.log.debug("Move attempt by \(self.currentPlayer.symbol) at (\(row), \(col))")

        guard row >= 0, row < boardSize, col >= 0, col < boardSize else {
            Self.log.info("Move failed: (\(row), \(col)) out of bounds")
            return .failureInvalidCoordinates
        }
        guard gameState == .ongoing else {
            Self.log.info("Move failed: game already over (\(String(describing: self.gameState)))")
            return .failureGameAlreadyOver
        }

        let moveBit = positionToBit(row: row, col: col)
        guard (xBoard | oBoard) & moveBit == 0 else {
            Self.log.info("Move failed: (\(row), \(col)) already taken")
            return .failurePositionTaken
        }

        if currentPlayer == .x { xBoard |= moveBit } else { oBoard |= moveBit }
        let mover = currentPlayer
        moveHistory.append(MoveRecord(row: row, col: col, player: mover))

        let playerBoard = mover == .x ? xBoard : oBoard
        if checkWin(for: playerBoard) {
            gameState = .won(mover)
            Self.log.info("Game won by \(mover.symbol)")
        } else if checkDraw() {
            gameState = .draw
            Self.log.info("Game draw")
        } else {
            currentPlayer = mover.next
            Self.log.debug("Next player: \(self.currentPlayer.symbol)")
        }
        return .success
    }

    /// Resets the game to its initial state.
    public func reset() {
        xBoard = 0
        oBoard = 0
        currentPlayer = .x
        gameState = .ongoing
        winningPattern = nil
        moveHistory.removeAll()
        Self.log.info("Game reset boardSize=\(self.boardSize)")
    }

    /// Whether there's at least one move that can be undone.
    public var canUndo: Bool { !moveHistory.isEmpty }

    /// Undoes the last move. If the game had ended, reverts it to `.ongoing`.
    /// - Returns: The move that was undone, or `nil` if there were no moves.
    @discardableResult
    public func undo() -> MoveRecord? {
        guard let last = moveHistory.popLast() else {
            return nil
        }
        let bit = positionToBit(row: last.row, col: last.col)
        if last.player == .x {
            xBoard &= ~bit
        } else {
            oBoard &= ~bit
        }
        currentPlayer = last.player
        gameState = .ongoing
        winningPattern = nil
        Self.log.info("Undo \(last.player.symbol) at (\(last.row), \(last.col))")
        return last
    }

    /// Returns the winning line coordinates when the game is won.
    public func getWinningPatternCoordinates() -> [(row: Int, col: Int)]? {
        guard case .won = gameState, let pattern = winningPattern else {
            return nil
        }
        let totalCells = boardSize * boardSize
        var coordinates: [(row: Int, col: Int)] = []
        coordinates.reserveCapacity(boardSize)

        for position in 0..<totalCells where (pattern & (1 << position)) != 0 {
            coordinates.append((row: position / boardSize, col: position % boardSize))
        }

        return coordinates
    }

    /// Returns the player at the given board position, or `nil` if empty / out of bounds.
    public func getPlayerAt(row: Int, col: Int) -> Player? {
        guard row >= 0, row < boardSize, col >= 0, col < boardSize else {
            return nil
        }
        let bit = positionToBit(row: row, col: col)
        if xBoard & bit != 0 {
            return .x
        }
        if oBoard & bit != 0 {
            return .o
        }
        return nil
    }

    /// Subscript access to `getPlayerAt(row:col:)`.
    public subscript(row: Int, col: Int) -> Player? { getPlayerAt(row: row, col: col) }

    // MARK: - Snapshot / Restore

    /// Captures the current logical state in a serializable snapshot.
    public func snapshot() -> GameSnapshot {
        GameSnapshot(
            boardSize: boardSize,
            xBoard: UInt64(bitPattern: Int64(xBoard)),
            oBoard: UInt64(bitPattern: Int64(oBoard)),
            currentPlayer: currentPlayer,
            gameState: gameState,
            moveHistory: moveHistory
        )
    }

    /// Restores a `GameLogic` from a previously captured snapshot.
    ///
    /// Validates that bitboards don't overlap, fit within the board, and that
    /// the move history length matches the number of placed pieces.
    /// - Returns: `nil` if the snapshot is invalid or corrupt.
    public static func restored(from snapshot: GameSnapshot) -> GameLogic? {
        guard let instance = GameLogic(boardSize: snapshot.boardSize) else {
            return nil
        }

        let xBoard = Int(Int64(bitPattern: snapshot.xBoard))
        let oBoard = Int(Int64(bitPattern: snapshot.oBoard))
        let validMask = instance.fullBoardMask

        guard xBoard >= 0, oBoard >= 0 else {
            log.error("Snapshot rejected: negative bitboard value")
            return nil
        }
        guard (xBoard & oBoard) == 0 else {
            log.error("Snapshot rejected: overlapping bitboards")
            return nil
        }
        guard ((xBoard | oBoard) & ~validMask) == 0 else {
            log.error("Snapshot rejected: bits outside valid board mask")
            return nil
        }

        let pieceCount = xBoard.nonzeroBitCount + oBoard.nonzeroBitCount
        guard snapshot.moveHistory.count == pieceCount else {
            log.error("Snapshot rejected: moveHistory count (\(snapshot.moveHistory.count)) != piece count (\(pieceCount))")
            return nil
        }

        instance.xBoard = xBoard
        instance.oBoard = oBoard
        instance.currentPlayer = snapshot.currentPlayer
        instance.gameState = snapshot.gameState
        instance.moveHistory = snapshot.moveHistory

        if case .won(let winner) = snapshot.gameState {
            _ = instance.checkWin(for: winner == .x ? xBoard : oBoard)
        }
        log.info("GameLogic restored from snapshot boardSize=\(instance.boardSize)")
        return instance
    }

    // MARK: - Private Helpers

    private func positionToBit(row: Int, col: Int) -> Int { 1 << (row * boardSize + col) }

    private static func generateWinningPatterns(boardSize: Int) -> [Int] {
        let dimension = boardSize
        let rows = (0..<dimension).map { row in
            (0..<dimension).reduce(0) { partialResult, column in
                partialResult | (1 << (row * dimension + column))
            }
        }
        let cols = (0..<dimension).map { column in
            (0..<dimension).reduce(0) { partialResult, row in
                partialResult | (1 << (row * dimension + column))
            }
        }
        let diag = (0..<dimension).reduce(0) { partialResult, offset in
            partialResult | (1 << (offset * dimension + offset))
        }
        let antiDiag = (0..<dimension).reduce(0) { partialResult, offset in
            partialResult | (1 << (offset * dimension + (dimension - 1 - offset)))
        }
        return rows + cols + [diag, antiDiag]
    }

    private func checkWin(for playerBoard: Int) -> Bool {
        guard let patterns = GameLogic.cachedWinningPatterns[boardSize] else {
            assertionFailure("Winning patterns missing for boardSize \(boardSize)")
            return false
        }
        for pattern in patterns where (playerBoard & pattern) == pattern {
            winningPattern = pattern
            return true
        }
        return false
    }

    private func checkDraw() -> Bool {
        (xBoard | oBoard) == fullBoardMask
    }
}
