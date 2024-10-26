import os
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

class GameScene: SKScene {
    fileprivate var boardSize: Int = 3 // Default to 3x3 board, configurable
    fileprivate var board: [[SKSpriteNode?]] = []
    fileprivate var xBoard: Int = 0 // Bit representation of X's moves
    fileprivate var oBoard: Int = 0 // Bit representation of O's moves
    fileprivate var currentPlayer: Player = .x
    fileprivate var winningLine: SKShapeNode? // To store the winning line
    fileprivate var gameState: GameState = .ongoing // Track the current state of the game
    
    // MARK: - Enums

    /// Enumeration for players, representing X and O with unique properties.
    enum Player: Int {
        case x = 1, o

        var symbol: String {
            @inline(__always) get {
                ["❌", "⭕"][rawValue - 1]
            }
        }

        var isTextBased: Bool {
            @inline(__always) get {
                self == .x
            }
        }

        var fontColor: GameColor {
            @inline(__always) get {
                [GameColor.red, GameColor.blue][rawValue - 1]
            }
        }

        var next: Player {
            @inline(__always) get {
                self == .x ? .o : .x
            }
        }
    }

    /// Enumeration for the game state, indicating whether the game is ongoing, won, or a draw.
    enum GameState {
        case ongoing
        case won
        case draw
    }

    private var winningPatterns: [Int] = [] // Store generated winning patterns based on board size

    class func newGameScene(boardSize: Int = 3) -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            os_log("Failed to load GameScene.sks")
            abort()
        }
        scene.boardSize = boardSize
        scene.generateWinningPatterns()
        return scene
    }

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTouch(at: touch.location(in: self))
    }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        handleTouch(at: event.location(in: self))
    }
    #endif

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

    override func didMove(to view: SKView) {
        drawBoard()
    }

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

    @inline(__always)
    private func positionToBit(row: Int, col: Int) -> Int {
        return 1 << (row * boardSize + col)
    }

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

    @inline(never)
    fileprivate func checkWin(for playerBoard: Int) -> Bool {
        return winningPatterns.contains { (playerBoard & $0) == $0 }
    }

    @inline(never)
    fileprivate func checkDraw() -> Bool {
        let fullBoard = (1 << (boardSize * boardSize)) - 1
        return (xBoard | oBoard) == fullBoard
    }

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
            os_log("Player \(self.currentPlayer.rawValue) wins!")
            gameState = .won // Update the game state to won
            drawWinningLine(for: winningPattern)
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        } else if checkDraw() {
            os_log("It's a draw!")
            gameState = .draw // Update the game state to draw
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        } else {
            currentPlayer = currentPlayer.next
        }
    }

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
            line.name = "winningLine" // Tag the line for removal during reset
            
            // Add line to the scene
            addChild(line)
            winningLine = line // Store the line so it can be removed later
        }
    }
}
