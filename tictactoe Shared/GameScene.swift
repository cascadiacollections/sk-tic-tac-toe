import SpriteKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Cross-platform color type alias for convenience
#if os(iOS)
typealias GameColor = UIColor
#elseif os(macOS)
typealias GameColor = NSColor
#endif

/// Main game scene for the Tic-Tac-Toe game using SpriteKit.
class GameScene: SKScene {
    // MARK: - Properties
    
    fileprivate var boardSize: Int = 3 // Default to 3x3 board, configurable
    fileprivate var board: [[SKSpriteNode?]] = [] // 2D array to store each cell node on the board
    fileprivate var xBoard: Int = 0 // Bit representation of X's moves
    fileprivate var oBoard: Int = 0 // Bit representation of O's moves
    fileprivate var currentPlayer: Player = .x // Tracks the current player (X or O)
    fileprivate var winningLine: SKShapeNode? // Reference to the winning line to remove on reset
    
    // MARK: - Player Enum
    
    /// Enumeration for players, representing X and O with unique properties.
    enum Player: Int {
        case x = 1, o
        
        /// The symbol used for the player (X or O).
        var symbol: String {
            @inline(__always) get {
                ["❌", "⭕"][rawValue - 1]
            }
        }
        
        /// Boolean indicating if the player uses text-based rendering.
        var isTextBased: Bool {
            @inline(__always) get {
                self == .x
            }
        }
        
        /// The color associated with the player (red for X, blue for O).
        var fontColor: GameColor {
            @inline(__always) get {
                [GameColor.red, GameColor.blue][rawValue - 1]
            }
        }
        
        /// Returns the opposite player (for switching turns).
        var next: Player {
            @inline(__always) get {
                self == .x ? .o : .x
            }
        }
    }
    
    private var winningPatterns: [Int] = [] // Array of bit patterns representing all possible win conditions
    
    // MARK: - Scene Initialization
    
    /// Factory method to create a new GameScene with a specified board size.
    ///
    /// - Parameter boardSize: The size of the Tic-Tac-Toe board (e.g., 3 for 3x3).
    /// - Returns: A configured `GameScene` instance.
    class func newGameScene(boardSize: Int = 3) -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.boardSize = boardSize
        scene.generateWinningPatterns()
        return scene
    }
    
    // MARK: - Touch Handling
    
    #if os(iOS)
    /// Handles touch events for iOS, calculating the touch location.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTouch(at: touch.location(in: self))
    }
    #elseif os(macOS)
    /// Handles mouse click events for macOS, calculating the click location.
    override func mouseDown(with event: NSEvent) {
        handleTouch(at: event.location(in: self))
    }
    #endif
    
    /// Handles the player's touch to determine which cell was tapped.
    ///
    /// - Parameter location: The CGPoint location of the touch or click in the scene.
    private func handleTouch(at location: CGPoint) {
        let cellSize = min(size.width, size.height) / CGFloat(boardSize)
        let xOffset = -cellSize * CGFloat(boardSize) / 2
        let yOffset = -cellSize * CGFloat(boardSize) / 2
        
        let col = Int((location.x - xOffset) / cellSize)
        let row = Int((location.y - yOffset) / cellSize)
        
        if row >= 0 && row < boardSize && col >= 0 && col < boardSize {
            makeMove(row: row, col: col)
        }
    }
    
    // MARK: - Board Setup and Reset
    
    /// Draws the board by creating cell nodes and positioning them.
    fileprivate func drawBoard() {
        let cellSize = min(size.width, size.height) / CGFloat(boardSize)
        let xOffset = -cellSize * CGFloat(boardSize) / 2
        let yOffset = -cellSize * CGFloat(boardSize) / 2
        
        board = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let cell = SKSpriteNode(color: GameColor.gray, size: CGSize(width: cellSize - 10, height: cellSize - 10))
                cell.position = CGPoint(x: xOffset + CGFloat(col) * cellSize + cellSize / 2,
                                        y: yOffset + CGFloat(row) * cellSize + cellSize / 2)
                cell.name = "\(row)-\(col)"
                addChild(cell)
                board[row][col] = cell
            }
        }
    }
    
    /// Resets the board by clearing cells and resetting the game state.
    fileprivate func resetBoard() {
        while let lineNode = childNode(withName: "winningLine") {
            lineNode.removeFromParent()
        }
        board.flatMap { $0 }.forEach { $0?.removeAllChildren() }
        xBoard = 0
        oBoard = 0
        currentPlayer = Bool.random() ? .x : .o
    }
    
    // MARK: - Bitwise Board Management
    
    /// Converts a row and column into a unique bit position.
    ///
    /// - Parameters:
    ///   - row: The row of the cell.
    ///   - col: The column of the cell.
    /// - Returns: An integer with the bit set for the cell's position.
    @inline(__always)
    private func positionToBit(row: Int, col: Int) -> Int {
        return 1 << (row * boardSize + col)
    }
    
    /// Generates winning patterns for the current board size.
    private func generateWinningPatterns() {
        winningPatterns.removeAll()
        
        winningPatterns.append(contentsOf: (0..<boardSize).map { row in
            (0..<boardSize).reduce(0) { $0 | positionToBit(row: row, col: $1) }
        })
        
        winningPatterns.append(contentsOf: (0..<boardSize).map { col in
            (0..<boardSize).reduce(0) { $0 | positionToBit(row: $1, col: col) }
        })
        
        var diagonalPattern1 = 0
        var diagonalPattern2 = 0
        for i in 0..<boardSize {
            diagonalPattern1 |= positionToBit(row: i, col: i)
            diagonalPattern2 |= positionToBit(row: i, col: boardSize - 1 - i)
        }
        winningPatterns.append(diagonalPattern1)
        winningPatterns.append(diagonalPattern2)
    }
    
    /// Checks if the provided player board matches any winning pattern.
    ///
    /// - Parameter playerBoard: Bit representation of the current player’s board.
    /// - Returns: `true` if the player has a winning pattern, `false` otherwise.
    @inline(never)
    fileprivate func checkWin(for playerBoard: Int) -> Bool {
        return winningPatterns.contains { (playerBoard & $0) == $0 }
    }
    
    /// Checks if the board is completely filled, indicating a draw.
    ///
    /// - Returns: `true` if there are no empty spaces, `false` otherwise.
    fileprivate func checkDraw() -> Bool {
        let fullBoard = (1 << (boardSize * boardSize)) - 1
        return (xBoard | oBoard) == fullBoard
    }
    
    // MARK: - Game Logic
    
    /// Makes a move for the current player at the specified row and column.
    ///
    /// - Parameters:
    ///   - row: The row of the move.
    ///   - col: The column of the move.
    func makeMove(row: Int, col: Int) {
        let moveBit = positionToBit(row: row, col: col)
        
        if (xBoard | oBoard) & moveBit != 0 {
            return // Position already taken
        }
        
        if currentPlayer == .x {
            xBoard |= moveBit
        } else {
            oBoard |= moveBit
        }
        
        if let tile = board[row][col] {
            if currentPlayer.isTextBased {
                let label = SKLabelNode(text: currentPlayer.symbol)
                label.fontSize = tile.frame.size.height * 0.8
                label.horizontalAlignmentMode = .center
                label.verticalAlignmentMode = .center
                label.position = CGPoint(x: 0, y: 0)
                label.fontColor = currentPlayer.fontColor
                tile.addChild(label)
            } else {
                let circle = SKShapeNode(circleOfRadius: tile.frame.size.height * 0.35)
                circle.strokeColor = currentPlayer.fontColor
                circle.lineWidth = 10.0
                circle.position = CGPoint(x: 0, y: 0)
                tile.addChild(circle)
            }
        }
        
        if let winningPattern = winningPatterns.first(where: { (currentPlayer == .x ? xBoard : oBoard) & $0 == $0 }) {
            print("Player \(currentPlayer.rawValue) wins!")
            drawWinningLine(for: winningPattern)
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        } else if checkDraw() {
            print("It's a draw!")
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        } else {
            currentPlayer = currentPlayer.next
        }
    }
    
    /// Draws a line across the winning cells.
    ///
    /// - Parameter winningPattern: The bit pattern representing the winning line.
    fileprivate func drawWinningLine(for winningPattern: Int) {
        var winningCoordinates: [(Int, Int)] = []
        
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if winningPattern & positionToBit(row: row, col: col) != 0 {
                    winningCoordinates.append((row, col))
                }
            }
        }
        
        if let start = winningCoordinates.first,
           let end = winningCoordinates.last,
           let startNode = board[start.0][start.1],
           let endNode = board[end.0][end.1] {
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: startNode.position.x, y: startNode.position.y))
            path.addLine(to: CGPoint(x: endNode.position.x, y: endNode.position.y))
            
            let line = SKShapeNode(path: path)
            line.strokeColor = currentPlayer.fontColor
            line.lineWidth = 10.0
            line.name = "winningLine"
            
            addChild(line)
            winningLine = line
        }
    }
}
