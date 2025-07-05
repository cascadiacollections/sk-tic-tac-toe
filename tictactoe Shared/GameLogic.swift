import Foundation
#if canImport(os)
import os.log
#endif

public enum Player: Int, CaseIterable {
    case x = 1, o
    public var symbol: String { ["❌", "⭕"][rawValue - 1] }
    public var next: Player { self == .x ? .o : .x }
}

public enum GameState: Equatable {
    case ongoing
    case won(Player)
    case draw

    public static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.ongoing, .ongoing), (.draw, .draw):
            return true
        case (.won(let player1), .won(let player2)):
            return player1 == player2
        default:
            return false
        }
    }
}

public enum MoveOutcome: Equatable {
    case success
    case failure_positionTaken
    case failure_invalidCoordinates
    case failure_gameAlreadyOver
}

/// Encapsulates the logic for a Tic Tac Toe game on an NxN board.
public final class GameLogic {

    #if canImport(os)
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp.tictactoe", category: "GameLogic")
    #endif

    /// The size of the board (NxN).
    public let boardSize: Int

    /// The player who has the current turn.
    public private(set) var currentPlayer: Player = .x

    /// The current state of the game.
    public private(set) var gameState: GameState = .ongoing

    private var xBoard = 0
    private var oBoard = 0

    /// Cached winning patterns for different board sizes.
    public private(set) static var cachedWinningPatterns: [Int: [Int]] = [:]

    private var winningPattern: Int?

    private enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case error = "ERROR"
    }

    /// Creates a new game logic instance for a board of the specified size.
    /// - Parameter boardSize: Size of the board (NxN). Must be at least 1.
    public init?(boardSize: Int = 3) {
        self.boardSize = boardSize

        guard boardSize >= 1 else {
            self.log(.error, "Initialization failed: Board size \(boardSize) must be at least 1.")
            return nil
        }

        if GameLogic.cachedWinningPatterns[boardSize] == nil {
            self.log(.debug, "Generating and caching winning patterns for board size \(boardSize)")
            GameLogic.cachedWinningPatterns[boardSize] = GameLogic.generateWinningPatterns(boardSize: boardSize)
        }
        self.log(.info, "GameLogic initialized with board size \(boardSize). Current player: \(self.currentPlayer.symbol)")
    }

    /// Attempts to make a move at the specified board coordinates.
    /// - Parameters:
    ///   - row: The row index (0-based).
    ///   - col: The column index (0-based).
    /// - Returns: `MoveOutcome` indicating success or failure reason.
    @discardableResult
    public func makeMove(row: Int, col: Int) -> MoveOutcome {
        self.log(.debug, "Attempting move by \(self.currentPlayer.symbol) at (\(row), \(col))")

        guard row >= 0, row < boardSize, col >= 0, col < boardSize else {
            self.log(.info, "Move failed: Coordinates (\(row), \(col)) out of bounds [0..<\(self.boardSize)]")
            return .failure_invalidCoordinates
        }
        guard gameState == .ongoing else {
            self.log(.info, "Move failed: Game already over (state: \(String(describing: self.gameState)))")
            return .failure_gameAlreadyOver
        }

        let moveBit = positionToBit(row: row, col: col)
        let occupiedMask = xBoard | oBoard

        if (occupiedMask & moveBit) != 0 {
            self.log(.info, "Move failed: Position (\(row), \(col)) already taken.")
            return .failure_positionTaken
        }

        if currentPlayer == .x {
            xBoard |= moveBit
            self.log(.debug, "X placed at (\(row), \(col)). xBoard: \(xBoard)")
        } else {
            oBoard |= moveBit
            self.log(.debug, "O placed at (\(row), \(col)). oBoard: \(oBoard)")
        }

        let currentPlayerBoard = (currentPlayer == .x) ? xBoard : oBoard
        if checkWin(for: currentPlayerBoard) {
            gameState = .won(currentPlayer)
            self.log(.info, "Game won by \(self.currentPlayer.symbol)")
        } else if checkDraw() {
            gameState = .draw
            self.log(.info, "Game ended in a draw.")
        } else {
            currentPlayer = currentPlayer.next
            self.log(.debug, "Move successful. Next player: \(self.currentPlayer.symbol)")
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
        self.log(.info, "Game reset. Board size \(self.boardSize). Current player: \(self.currentPlayer.symbol)")
    }

    /// Returns the coordinates of the winning pattern if the game is won.
    /// - Returns: Array of `(row, col)` tuples representing the winning line, or `nil` if no winner.
    public func getWinningPatternCoordinates() -> [(row: Int, col: Int)]? {
        guard case .won = gameState, let pattern = winningPattern else {
            return nil
        }

        let totalSquares = boardSize * boardSize
        let coordinates = (0..<totalSquares).compactMap { index -> (row: Int, col: Int)? in
            (pattern & (1 << index)) != 0 ? (index / boardSize, index % boardSize) : nil
        }
        return coordinates.sorted { ($0.row * boardSize + $0.col) < ($1.row * boardSize + $1.col) }
    }

    /// Returns the player at the specified board position.
    /// - Parameters:
    ///   - row: The row index (0-based).
    ///   - col: The column index (0-based).
    /// - Returns: The `Player` at the position, or `nil` if empty or out of bounds.
    public func getPlayerAt(row: Int, col: Int) -> Player? {
        guard row >= 0, row < boardSize, col >= 0, col < boardSize else {
            return nil
        }
        let bit = positionToBit(row: row, col: col)
        if (xBoard & bit) != 0 {
            return .x
        } else if (oBoard & bit) != 0 {
            return .o
        } else {
            return nil
        }
    }

    /// Access the player at the specified position via subscript syntax.
    /// - Parameters:
    ///   - row: The row index (0-based).
    ///   - col: The column index (0-based).
    public subscript(row: Int, col: Int) -> Player? {
        return getPlayerAt(row: row, col: col)
    }

    private func positionToBit(row: Int, col: Int) -> Int {
        1 << (row * boardSize + col)
    }

    private static func generateWinningPatterns(boardSize: Int) -> [Int] {
        let dimensionRange = 0..<boardSize
        let totalSquares = boardSize * boardSize

        guard totalSquares <= Int.bitWidth else {
            logStatic(.error, "Board size \(boardSize) too large, exceeds Int bit width (\(Int.bitWidth))")
            return []
        }

        let rowPatterns = dimensionRange.map { row in
            dimensionRange.reduce(0) { $0 | (1 << (row * boardSize + $1)) }
        }
        let colPatterns = dimensionRange.map { col in
            dimensionRange.reduce(0) { $0 | (1 << ($1 * boardSize + col)) }
        }
        let diagonal = dimensionRange.reduce(0) { $0 | (1 << ($1 * boardSize + $1)) }
        let antiDiagonal = dimensionRange.reduce(0) { $0 | (1 << ($1 * boardSize + (boardSize - 1 - $1))) }

        return rowPatterns + colPatterns + [diagonal, antiDiagonal]
    }

    private func checkWin(for playerBoard: Int) -> Bool {
        guard let patterns = GameLogic.cachedWinningPatterns[self.boardSize] else {
            self.log(.error, "Consistency error: Winning patterns not found for board size \(self.boardSize)")
            assertionFailure("Winning patterns not found for board size \(self.boardSize)")
            return false
        }

        for pattern in patterns {
            if (playerBoard & pattern) == pattern {
                winningPattern = pattern
                return true
            }
        }
        return false
    }

    private func checkDraw() -> Bool {
        let totalSquares = boardSize * boardSize
        guard totalSquares < Int.bitWidth else { return false }

        let fullBoard = (1 << totalSquares) - 1
        return (xBoard | oBoard) == fullBoard
    }

    // MARK: - Logging

    private func log(_ level: LogLevel, _ message: String) {
        #if canImport(os)
        os_log("%{public}@ - %{public}@", log: Self.log, type: osLogType(for: level), level.rawValue, message)
        #else
        print("[\(level.rawValue)] \(message)")
        #endif
    }

    private static func logStatic(_ level: LogLevel, _ message: String) {
        #if canImport(os)
        os_log("%{public}@ - %{public}@", log: log, type: osLogType(for: level), level.rawValue, message)
        #else
        print("[\(level.rawValue)] \(message)")
        #endif
    }

    private static func osLogType(for level: LogLevel) -> OSLogType {
        #if canImport(os)
        switch level {
        case .debug:
            return .debug
        case .info:
            return .info
        case .error:
            return .error
        }
        #else
        // Dummy fallback, won't be used without os imported
        fatalError("osLogType called without os module")
        #endif
    }

    private func osLogType(for level: LogLevel) -> OSLogType {
        return Self.osLogType(for: level)
    }
}
