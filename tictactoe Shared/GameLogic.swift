import Foundation

#if canImport(os)
import os.log // For logging
#endif

// Define a logger instance (adjust subsystem as needed)
#if canImport(os)
private let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp.tictactoe", category: "GameLogic")
#endif

/// Manages the logic for an n x n Tic-Tac-Toe game using bitboards.
class GameLogic {

    // MARK: - Enums

    /// Represents the players in the game.
    enum Player: Int, CaseIterable { // Added CaseIterable for convenience if needed elsewhere
        case x = 1, o
        /// The visual symbol for the player ("❌" or "⭕").
        var symbol: String { ["❌", "⭕"][rawValue - 1] }
        /// The next player in turn.
        var next: Player { self == .x ? .o : .x }
    }

    /// Represents the possible states of the game.
    enum GameState: Equatable {
        case ongoing
        case won(Player)
        case draw

        static func == (lhs: GameState, rhs: GameState) -> Bool {
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

    /// Represents the outcome of attempting to make a move.
    enum MoveOutcome: Equatable {
        case success // Move made, game continues or ended
        case failure_positionTaken
        case failure_invalidCoordinates
        case failure_gameAlreadyOver
    }

    // MARK: - Properties

    /// The dimension of the board (e.g., 3 for a 3x3 board).
    let boardSize: Int // Make immutable after init
    /// The player whose turn it currently is.
    private(set) var currentPlayer: Player = .x
    /// The current state of the game (ongoing, won, or draw).
    private(set) var gameState: GameState = .ongoing

    // Bitboards representing the positions occupied by each player.
    private var xBoard = 0
    private var oBoard = 0

    // Cache for winning patterns to avoid recalculation for the same board size.
    private static var cachedWinningPatterns: [Int: [Int]] = [:]
    // The specific bitmask pattern that resulted in the win, if any.
    private var winningPattern: Int?

    // MARK: - Initialization

    /// Initializes a new Tic-Tac-Toe game logic manager.
    /// - Parameter boardSize: The dimension of the board (e.g., 3 for 3x3). Must be 1 or greater.
    /// - Returns: A new `GameLogic` instance, or `nil` if the board size is invalid.
    init?(boardSize: Int = 3) {
        guard boardSize >= 1 else {
            #if canImport(os)
            os_log(.error, log: log, "Initialization failed: Board size %d must be at least 1.", boardSize)
            #endif
            return nil
        }
        // Consider adding a practical upper limit if memory/Int size is a concern
        // guard boardSize <= 5 else { // Example: Max 5x5 for standard Int
        //     #if canImport(os)
        //     os_log(.error, log: log, "Initialization failed: Board size %d too large.", boardSize)
        //     #endif
        //     return nil
        // }

        self.boardSize = boardSize

        // Generate/Cache winning patterns if not already done for this size
        if GameLogic.cachedWinningPatterns[boardSize] == nil {
            #if canImport(os)
            os_log(.debug, log: log, "Generating and caching winning patterns for board size %d", boardSize)
            #endif
            GameLogic.cachedWinningPatterns[boardSize] = GameLogic.generateWinningPatterns(boardSize: boardSize)
        }
        #if canImport(os)
            os_log(.info, log: log, "GameLogic initialized with board size %d. Current player: %{public}@", boardSize, self.currentPlayer.symbol)
            #endif
    }

    // MARK: - Public Methods

    /// Attempts to place the current player's mark at the specified position.
    /// - Parameters:
    ///   - row: The row index (0-based).
    ///   - col: The column index (0-based).
    /// - Returns: A `MoveOutcome` indicating the result of the move attempt.
    @discardableResult // Allow calling without using the return value if not needed
    func makeMove(row: Int, col: Int) -> MoveOutcome {
        #if canImport(os)
            os_log(.debug, log: log, "Attempting move by %{public}@ at (%d, %d)", self.currentPlayer.symbol, row, col)
            #endif

        guard row >= 0 && row < boardSize && col >= 0 && col < boardSize else {
            #if canImport(os)
            os_log(.info, log: log, "Move failed: Coordinates (%d, %d) out of bounds [0..<%d]", row, col, self.boardSize)
            #endif
             return .failure_invalidCoordinates
        }
        guard gameState == .ongoing else {
            #if canImport(os)
            os_log(.info, log: log, "Move failed: Game already over (state: %{public}@)", String(describing: self.gameState))
            #endif
            return .failure_gameAlreadyOver
        }

        let moveBit = positionToBit(row: row, col: col)
        let occupiedMask = xBoard | oBoard

        // Check if the position is already taken
        if (occupiedMask & moveBit) != 0 {
             #if canImport(os)
            os_log(.info, log: log, "Move failed: Position (%d, %d) already taken.", row, col)
            #endif
            return .failure_positionTaken
        }

        // Place the mark on the appropriate bitboard
        if currentPlayer == .x {
            xBoard |= moveBit
             #if canImport(os)
            os_log(.debug, log: log, "X placed at (%d, %d). xBoard: %d", row, col, xBoard)
            #endif
        } else {
            oBoard |= moveBit
             #if canImport(os)
            os_log(.debug, log: log, "O placed at (%d, %d). oBoard: %d", row, col, oBoard)
            #endif
        }

        // Check for game end conditions
        let currentPlayerBoard = (currentPlayer == .x) ? xBoard : oBoard
        if checkWin(for: currentPlayerBoard) {
            gameState = .won(currentPlayer)
            #if canImport(os)
            os_log(.info, log: log, "Game won by %{public}@", self.currentPlayer.symbol)
            #endif
        } else if checkDraw() {
            gameState = .draw
            #if canImport(os)
            os_log(.info, log: log, "Game ended in a draw.")
            #endif
        } else {
            // Game continues, switch player
            _ = currentPlayer
            currentPlayer = currentPlayer.next
             #if canImport(os)
            os_log(.debug, log: log, "Move successful. Next player: %{public}@", self.currentPlayer.symbol)
            #endif
        }
        return .success
    }

    /// Resets the game state to the beginning (empty board, X's turn).
    /// Keeps the same board size.
    func reset() {
        xBoard = 0
        oBoard = 0
        currentPlayer = .x
        gameState = .ongoing
        winningPattern = nil // Clear the stored winning pattern
        #if canImport(os)
            os_log(.info, log: log, "Game reset. Board size %d. Current player: %{public}@", self.boardSize, self.currentPlayer.symbol)
            #endif
    }

    /// Returns the coordinates of the cells forming the winning line, if the game has been won.
    /// - Returns: An array of (row, col) tuples representing the winning line, sorted by index, or `nil` if the game is not won or no winning pattern is stored.
    func getWinningPatternCoordinates() -> [(row: Int, col: Int)]? {
        guard case .won = gameState, let pattern = winningPattern else {
             return nil // Game not won or pattern not set
        }

        var coordinates: [(row: Int, col: Int)] = []
        let totalSquares = boardSize * boardSize
        for index in 0..<totalSquares {
            // Check if the bit at 'index' is set in the winning pattern
            if (pattern & (1 << index)) != 0 {
                let row = index / boardSize
                let col = index % boardSize
                coordinates.append((row: row, col: col))
            }
        }
         // Sorting ensures consistent order for testing/UI
        return coordinates.sorted { ($0.row * boardSize + $0.col) < ($1.row * boardSize + $1.col) }
    }

     /// Gets the player occupying a specific cell, or nil if empty.
     /// Useful for UI display without exposing bitboards directly.
     /// - Parameters:
     ///   - row: The row index (0-based).
     ///   - col: The column index (0-based).
     /// - Returns: The `Player` (.x or .o) at the cell, or `nil` if the cell is empty or coordinates are invalid.
     func getPlayerAt(row: Int, col: Int) -> Player? {
         guard row >= 0 && row < boardSize && col >= 0 && col < boardSize else {
             return nil // Invalid coordinates
         }
         let bit = positionToBit(row: row, col: col)
         if (xBoard & bit) != 0 {
             return .x
         } else if (oBoard & bit) != 0 {
             return .o
         } else {
             return nil // Cell is empty
         }
     }

    // MARK: - Private Helper Methods

    /// Converts a (row, col) position to its corresponding bit position in the bitboard.
    private func positionToBit(row: Int, col: Int) -> Int {
        // Assumes row/col are already validated by caller (makeMove/getPlayerAt)
        return 1 << (row * boardSize + col)
    }

    /// Generates all winning bitmask patterns for a given board size.
    private static func generateWinningPatterns(boardSize: Int) -> [Int] {
        var patterns = [Int]()
        let dimensionRange = 0..<boardSize
        let totalSquares = boardSize * boardSize

        guard totalSquares <= Int.bitWidth else {
             // Prevent overflow if boardSize is excessively large
            #if canImport(os)
            os_log(.error, log: log, "Board size %d too large, exceeds Int bit width (%d)", boardSize, Int.bitWidth)
            #endif
             // Depending on desired behavior, could return empty or crash
             return [] // Return empty to prevent incorrect calculations
        }


        // Rows
        dimensionRange.forEach { row in
            patterns.append(dimensionRange.reduce(0) { acc, col in acc | (1 << (row * boardSize + col)) })
        }

        // Columns
        dimensionRange.forEach { col in
            patterns.append(dimensionRange.reduce(0) { acc, row in acc | (1 << (row * boardSize + col)) })
        }

        // Diagonal (top-left to bottom-right)
        patterns.append(dimensionRange.reduce(0) { acc, i in acc | (1 << (i * boardSize + i)) })

        // Anti-diagonal (top-right to bottom-left)
        patterns.append(dimensionRange.reduce(0) { acc, i in acc | (1 << (i * boardSize + (boardSize - 1 - i))) })

        return patterns
    }

    /// Checks if the given player's board contains a winning pattern.
    /// Sets `winningPattern` if a win is detected.
    private func checkWin(for playerBoard: Int) -> Bool {
        guard let patterns = GameLogic.cachedWinningPatterns[self.boardSize] else {
            // This should ideally not happen if init succeeded and caching worked
            #if canImport(os)
            os_log(.error, log: log, "Consistency error: Winning patterns not found for board size %d", self.boardSize)
            #endif
            assertionFailure("Winning patterns not found for board size \(self.boardSize)") // Crash in debug
            return false
        }

        for pattern in patterns {
            if (playerBoard & pattern) == pattern {
                winningPattern = pattern // Store the specific winning pattern
                return true
            }
        }
        return false
    }

    /// Checks if the game is a draw (all squares filled, no winner).
    private func checkDraw() -> Bool {
        let totalSquares = boardSize * boardSize
        // Handle potential overflow for large boards if not checked earlier
        guard totalSquares < Int.bitWidth else { return false } // Cannot be a draw if too large for bitboard

        // Check if all bits up to the maximum possible are set
        // Creates a mask like 0b111111111 (for 3x3)
        let fullBoard = (1 << totalSquares) - 1
        return (xBoard | oBoard) == fullBoard
    }
}
