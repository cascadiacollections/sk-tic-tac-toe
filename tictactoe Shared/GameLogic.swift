import Foundation
import os

// MARK: - Player

public enum Player: Int, CaseIterable, Sendable {
    case x = 1, o
    public var symbol: String { rawValue == 1 ? "❌" : "⭕" }
    public var next: Player { self == .x ? .o : .x }
}

// MARK: - GameState

public enum GameState: Equatable, Sendable {
    case ongoing
    case won(Player)
    case draw
}

// MARK: - MoveOutcome

public enum MoveOutcome: Equatable, Sendable {
    case success
    case failure_positionTaken
    case failure_invalidCoordinates
    case failure_gameAlreadyOver
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

    /// Winning-pattern cache shared across all instances.
    /// Populated once per board size; never mutated after insertion.
    nonisolated(unsafe) private static var cachedWinningPatterns: [Int: [Int]] = [:]

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
            return .failure_invalidCoordinates
        }
        guard gameState == .ongoing else {
            Self.log.info("Move failed: game already over (\(String(describing: self.gameState)))")
            return .failure_gameAlreadyOver
        }

        let moveBit = positionToBit(row: row, col: col)
        guard (xBoard | oBoard) & moveBit == 0 else {
            Self.log.info("Move failed: (\(row), \(col)) already taken")
            return .failure_positionTaken
        }

        if currentPlayer == .x { xBoard |= moveBit } else { oBoard |= moveBit }

        let playerBoard = currentPlayer == .x ? xBoard : oBoard
        if checkWin(for: playerBoard) {
            gameState = .won(currentPlayer)
            Self.log.info("Game won by \(self.currentPlayer.symbol)")
        } else if checkDraw() {
            gameState = .draw
            Self.log.info("Game draw")
        } else {
            currentPlayer = currentPlayer.next
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
        Self.log.info("Game reset boardSize=\(self.boardSize)")
    }

    /// Returns the winning line coordinates when the game is won.
    public func getWinningPatternCoordinates() -> [(row: Int, col: Int)]? {
        guard case .won = gameState, let pattern = winningPattern else { return nil }
        return (0..<boardSize * boardSize)
            .filter { (pattern & (1 << $0)) != 0 }
            .map { ($0 / boardSize, $0 % boardSize) }
            .sorted { $0.0 * boardSize + $0.1 < $1.0 * boardSize + $1.1 }
    }

    /// Returns the player at the given board position, or `nil` if empty / out of bounds.
    public func getPlayerAt(row: Int, col: Int) -> Player? {
        guard row >= 0, row < boardSize, col >= 0, col < boardSize else { return nil }
        let bit = positionToBit(row: row, col: col)
        if xBoard & bit != 0 { return .x }
        if oBoard & bit != 0 { return .o }
        return nil
    }

    /// Subscript access to `getPlayerAt(row:col:)`.
    public subscript(row: Int, col: Int) -> Player? { getPlayerAt(row: row, col: col) }

    // MARK: - Private Helpers

    private func positionToBit(row: Int, col: Int) -> Int { 1 << (row * boardSize + col) }

    private static func generateWinningPatterns(boardSize: Int) -> [Int] {
        let n = boardSize
        let rows      = (0..<n).map { r in (0..<n).reduce(0) { $0 | (1 << (r * n + $1)) } }
        let cols      = (0..<n).map { c in (0..<n).reduce(0) { $0 | (1 << ($1 * n + c)) } }
        let diag      = (0..<n).reduce(0) { $0 | (1 << ($1 * n + $1)) }
        let antiDiag  = (0..<n).reduce(0) { $0 | (1 << ($1 * n + (n - 1 - $1))) }
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

