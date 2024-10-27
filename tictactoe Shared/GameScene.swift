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
        var symbol: String { ["❌", "⭕"][rawValue - 1] }
        var isTextBased: Bool { self == .x }
        var fontColor: GameColor { [GameColor.red, GameColor.blue][rawValue - 1] }
        var next: Player { self == .x ? .o : .x }
    }

    /// Enumeration for the game state, indicating whether the game is ongoing, won, or a draw.
    enum GameState { case ongoing, won, draw }
    
    /// Possible winning patterns for square N x N grid.
    private static var winningPatterns: [Int] = []

    class func newGameScene(boardSize: Int = 3) -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            os_log("Failed to load GameScene.sks")
            abort()
        }
        scene.boardSize = boardSize
        winningPatterns = scene.generateWinningPatterns()
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
        let offset = -cellSize * CGFloat(boardSize) / 2

        let col = Int((location.x - offset) / cellSize)
        let row = Int((location.y - offset) / cellSize)

        if (0..<boardSize).contains(row) && (0..<boardSize).contains(col) {
            makeMove(row: row, col: col)
        }
    }

    override func didMove(to view: SKView) {
        drawBoard()
    }

    @inline(never)
    fileprivate func drawBoard() {
        let cellSize = min(size.width, size.height) / CGFloat(boardSize)
        let offset = -cellSize * CGFloat(boardSize) / 2
        board = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        
        (0..<boardSize * boardSize).forEach { i in
            let cell = SKSpriteNode(color: GameColor.gray, size: CGSize(width: cellSize - 10, height: cellSize - 10))
            cell.position = CGPoint(
                x: offset + (CGFloat(i % boardSize) + 0.5) * cellSize,
                y: offset + (CGFloat(i / boardSize) + 0.5) * cellSize
            )
            cell.name = "\(i / boardSize)-\(i % boardSize)"
            addChild(cell)
            board[i / boardSize][i % boardSize] = cell
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

    @inline(never)
    private func generateWinningPatterns() -> [Int] {
        var patterns = [Int]()
        
        // Row and Column patterns
        patterns.append(contentsOf: (0..<boardSize).flatMap { i in
            [
                (0..<boardSize).reduce(0) { $0 | positionToBit(row: i, col: $1) }, // Row pattern
                (0..<boardSize).reduce(0) { $0 | positionToBit(row: $1, col: i) }  // Column pattern
            ]
        })

        // Diagonal patterns
        patterns.append(contentsOf: [
            (0..<boardSize).reduce(0) { $0 | positionToBit(row: $1, col: $1) },
            (0..<boardSize).reduce(0) { $0 | positionToBit(row: $1, col: boardSize - 1 - $1) }
        ])
        
        return patterns
    }

    @inline(never)
    fileprivate func checkWin(for playerBoard: Int) -> Bool {
        return GameScene.winningPatterns.contains { (playerBoard & $0) == $0 }
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

        if let winningPattern = GameScene.winningPatterns.first(where: { (currentPlayer == .x ? xBoard : oBoard) & $0 == $0 }) {
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
