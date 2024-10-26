import SpriteKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
typealias GameColor = UIColor
#elseif os(macOS)
typealias GameColor = NSColor
#endif

/// Main game scene for a Tic-Tac-Toe game using SpriteKit.
class GameScene: SKScene {
    // MARK: - Properties
    
    /// Size of the Tic-Tac-Toe board, configurable.
    fileprivate var boardSize: Int = 3
    
    /// 2D array to store each cell node on the board.
    fileprivate var board: [[SKSpriteNode?]] = []
    
    /// Bit representation of X's moves.
    fileprivate var xBoard: Int = 0
    
    /// Bit representation of O's moves.
    fileprivate var oBoard: Int = 0
    
    /// Tracks the current player (X or O).
    fileprivate var currentPlayer: Player = .x
    
    /// Reference to the winning line to remove on reset.
    fileprivate var winningLine: SKShapeNode?
    
    /// Tracks the current state of the game.
    fileprivate var gameState: GameState = .ongoing
    
    /// Array of bit patterns representing all possible win conditions.
    private var winningPatterns: [Int] = []
    
    // MARK: - Enums
    
    /// Enum representing each player, X and O, with unique properties.
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
        
        /// Returns the opposite player, to switch turns.
        var next: Player {
            @inline(__always) get {
                self == .x ? .o : .x
            }
        }
    }
    
    /// Enum representing the game state, indicating if the game is ongoing, won, or a draw.
    enum GameState {
        case ongoing
        case won
        case draw
    }
    
    // MARK: - Scene Initialization
    
    /// Creates a new GameScene with a specified board size.
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
    /// Handles touch events for iOS by calculating the touch location.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTouch(at: touch.location(in: self))
    }
    #elseif os(macOS)
    /// Handles mouse click events for macOS by calculating the click location.
    override func mouseDown(with event: NSEvent) {
        handleTouch(at: event.location(in: self))
    }
    #endif
    
    /// Determines which cell was tapped based on the location of the touch.
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
                                        y: yOffset + CGFloat(row) * cellSize / 2)
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
        gameState = .ongoing // Reset the game state to ongoing
    }

    // MARK: - Game Logic
    
    /// Makes a move for the current player at the specified row and column.
    ///
    /// - Parameters:
    ///   - row: The row of the move.
    ///   - col: The column of the move.
    func makeMove(row: Int, col: Int) {
        // Prevent moves if the game is already won or drawn
        guard gameState == .ongoing else { return }
        
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
            gameState = .won // Update the game state to won
            drawWinningLine(for: winningPattern)
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        } else if checkDraw() {
            print("It's a draw!")
            gameState = .draw // Update the game state to draw
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

            let startX = startNode.position.x
            let startY = startNode.position.y
            let endX = endNode.position.x
            let endY = endNode.position.y

            // Create a path for the line
            let path = CGMutablePath()
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
            
            // Create the line node and add the name tag
            let line = SKShapeNode(path: path)
            line.strokeColor = currentPlayer.fontColor
            line.lineWidth = 10.0
            line.name = "winningLine"
            
            addChild(line)
            winningLine = line
        }
    }
    
    // MARK: - Utility Functions
    
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

    /// Checks if the provided player board matches any winning pattern.
    ///
    /// - Parameter playerBoard: Bit representation of the current player’s board.
    /// - Returns: `true` if the player has a winning pattern, `false` otherwise.
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

    /// Generates winning patterns for the current board size.
    private func generateWinningPatterns() {
        winningPatterns.removeAll()
        
        // Row patterns
        winningPatterns.append(contentsOf: (0..<boardSize).map { row in
            (0..<boardSize).reduce(0) { $0 | positionToBit(row: row, col: $1) }
        })

        // Column patterns
        winningPatterns.append(contentsOf: (0..<boardSize).map { col in
            (0..<boardSize).reduce(0) { $0 | positionToBit(row: $1, col: col) }
        })
        
        // Diagonal (top-left to bottom-right)
        var diagonalPattern1 = 0
        for i in 0..<boardSize {
            diagonalPattern1 |= positionToBit(row: i, col: i)
        }
        winningPatterns.append(diagonalPattern1)
        
        // Diagonal (top-right to bottom-left)
        var diagonalPattern2 = 0
        for i in 0..<boardSize {
            diagonalPattern2 |= positionToBit(row: i, col: boardSize - 1 - i)
        }
        winningPatterns.append(diagonalPattern2)
    }
}
