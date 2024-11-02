class GameLogic {
    enum Player: Int {
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

    private(set) var boardSize: Int
    private(set) var currentPlayer: Player = .x
    private(set) var gameState: GameState = .ongoing
    private var xBoard = 0, oBoard = 0
    private static var winningPatterns: [Int] = []
    private var winningPattern: Int?

    init(boardSize: Int = 3) {
        self.boardSize = boardSize
        GameLogic.winningPatterns = GameLogic.generateWinningPatterns(boardSize: boardSize)
    }

    func makeMove(row: Int, col: Int) -> Bool {
        guard gameState == .ongoing else { return false }

        let moveBit = positionToBit(row: row, col: col)
        if (xBoard | oBoard) & moveBit != 0 { return false } // Position taken

        if currentPlayer == .x {
            xBoard |= moveBit
        } else {
            oBoard |= moveBit
        }

        if checkWin(for: currentPlayer == .x ? xBoard : oBoard) {
            gameState = .won(currentPlayer)
        } else if checkDraw() {
            gameState = .draw
        } else {
            currentPlayer = currentPlayer.next
        }
        return true
    }

    private func positionToBit(row: Int, col: Int) -> Int {
        return 1 << (row * boardSize + col)
    }

    private static func generateWinningPatterns(boardSize: Int) -> [Int] {
        var patterns = [Int]()
        
        (0..<boardSize).forEach { i in
            patterns.append((0..<boardSize).reduce(0) { acc, j in acc | (1 << (i * boardSize + j)) })
            patterns.append((0..<boardSize).reduce(0) { acc, j in acc | (1 << (j * boardSize + i)) })
        }
        patterns.append((0..<boardSize).reduce(0) { acc, i in acc | (1 << (i * boardSize + i)) })
        patterns.append((0..<boardSize).reduce(0) { acc, i in acc | (1 << (i * boardSize + (boardSize - 1 - i))) })
        
        return patterns
    }

    private func checkWin(for playerBoard: Int) -> Bool {
        for pattern in GameLogic.winningPatterns {
            if (playerBoard & pattern) == pattern {
                winningPattern = pattern
                return true
            }
        }
        return false
    }

    private func checkDraw() -> Bool {
        let fullBoard = (1 << (boardSize * boardSize)) - 1
        return (xBoard | oBoard) == fullBoard
    }
    
    func getWinningPattern() -> [(row: Int, col: Int)]? {
        guard let pattern = winningPattern else { return nil }
        return (0..<boardSize * boardSize).compactMap { index in
            (pattern & (1 << index)) != 0 ? (index / boardSize, index % boardSize) : nil
        }
    }
}
