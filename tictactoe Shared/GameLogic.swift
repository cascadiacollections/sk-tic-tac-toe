import Foundation

#if canImport(os)
import os.log
#endif

#if canImport(os)
private let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp.tictactoe", category: "GameLogic")
#endif

class GameLogic {

    enum Player: Int, CaseIterable {
        case x = 1, o
        var symbol: String { ["❌", "⭕"][rawValue - 1] }
        var next: Player { self == .x ? .o : .x }
    }

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

    enum MoveOutcome: Equatable {
        case success
        case failure_positionTaken
        case failure_invalidCoordinates
        case failure_gameAlreadyOver
    }

    let boardSize: Int
    private(set) var currentPlayer: Player = .x
    private(set) var gameState: GameState = .ongoing

    private var xBoard = 0
    private var oBoard = 0

    private(set) static var cachedWinningPatterns: [Int: [Int]] = [:]
    private var winningPattern: Int?

    init?(boardSize: Int = 3) {
        guard boardSize >= 1 else {
            #if canImport(os)
            os_log(.error, log: log, "Initialization failed: Board size %d must be at least 1.", boardSize)
            #endif
            return nil
        }

        self.boardSize = boardSize

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

    @discardableResult
    func makeMove(row: Int, col: Int) -> MoveOutcome {
        #if canImport(os)
        os_log(.debug, log: log, "Attempting move by %{public}@ at (%d, %d)", self.currentPlayer.symbol, row, col)
        #endif

        guard row >= 0, row < boardSize, col >= 0, col < boardSize else {
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

        if (occupiedMask & moveBit) != 0 {
            #if canImport(os)
            os_log(.info, log: log, "Move failed: Position (%d, %d) already taken.", row, col)
            #endif
            return .failure_positionTaken
        }

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
            currentPlayer = currentPlayer.next
            #if canImport(os)
            os_log(.debug, log: log, "Move successful. Next player: %{public}@", self.currentPlayer.symbol)
            #endif
        }
        return .success
    }

    func reset() {
        xBoard = 0
        oBoard = 0
        currentPlayer = .x
        gameState = .ongoing
        winningPattern = nil
        #if canImport(os)
        os_log(.info, log: log, "Game reset. Board size %d. Current player: %{public}@", self.boardSize, self.currentPlayer.symbol)
        #endif
    }

    func getWinningPatternCoordinates() -> [(row: Int, col: Int)]? {
        guard case .won = gameState, let pattern = winningPattern else {
            return nil
        }

        let totalSquares = boardSize * boardSize
        let coordinates = (0..<totalSquares).compactMap { index -> (row: Int, col: Int)? in
            (pattern & (1 << index)) != 0 ? (index / boardSize, index % boardSize) : nil
        }
        return coordinates.sorted { ($0.row * boardSize + $0.col) < ($1.row * boardSize + $1.col) }
    }

    func getPlayerAt(row: Int, col: Int) -> Player? {
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

    private func positionToBit(row: Int, col: Int) -> Int {
        1 << (row * boardSize + col)
    }

    private static func generateWinningPatterns(boardSize: Int) -> [Int] {
        let dimensionRange = 0..<boardSize
        let totalSquares = boardSize * boardSize

        guard totalSquares <= Int.bitWidth else {
            #if canImport(os)
            os_log(.error, log: log, "Board size %d too large, exceeds Int bit width (%d)", boardSize, Int.bitWidth)
            #endif
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
            #if canImport(os)
            os_log(.error, log: log, "Consistency error: Winning patterns not found for board size %d", self.boardSize)
            #endif
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
}
