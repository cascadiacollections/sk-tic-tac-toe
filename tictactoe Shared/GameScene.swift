import SpriteKit
import AppKit

class GameScene: SKScene {
    fileprivate let boardSize = 3
    fileprivate var board: [[SKSpriteNode?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
    fileprivate var boardState: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 3)
    fileprivate var currentPlayer: Player = .x
    fileprivate var winningLine: SKShapeNode? // To store the winning line

    enum Player: Int {
        case x = 1
        case o = 2

        var symbol: String {
            return self == .x ? "❌" : "⭕"
        }

        var next: Player {
            return self == .x ? .o : .x
        }
    }

    class func newGameScene() -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }

        scene.scaleMode = .aspectFill
        return scene
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodesAtPoint = self.nodes(at: location)

        for node in nodesAtPoint {
            if let nodeName = node.name, nodeName.contains("-") {
                let coordinates = nodeName.split(separator: "-").compactMap { Int($0) }
                if coordinates.count == 2 {
                    makeMove(row: coordinates[0], col: coordinates[1])
                }
            }
        }
    }

    override func didMove(to view: SKView) {
        drawBoard()
    }

    fileprivate func drawBoard() {
        let cellSize = min(size.width, size.height) / CGFloat(boardSize)
        let xOffset = -cellSize * CGFloat(boardSize) / 2
        let yOffset = -cellSize * CGFloat(boardSize) / 2

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let cell = SKSpriteNode(color: SKColor.gray, size: CGSize(width: cellSize - 10, height: cellSize - 10))
                cell.position = CGPoint(x: xOffset + CGFloat(col) * cellSize + cellSize / 2,
                                        y: yOffset + CGFloat(row) * cellSize + cellSize / 2)
                cell.name = "\(row)-\(col)"
                addChild(cell)
                board[row][col] = cell
            }
        }
    }

    fileprivate func resetBoard() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                board[row][col]?.removeAllChildren()
                boardState[row][col] = 0
            }
        }
        currentPlayer = .x
        winningLine?.removeFromParent()  // Remove any previous winning line
    }

    fileprivate func checkLine(a: Int, b: Int, c: Int) -> Bool {
        return a != 0 && a == b && b == c
    }

    fileprivate func checkWin() -> (Int, [(Int, Int)]?) {
        // Check rows and columns
        for i in 0..<boardSize {
            if checkLine(a: boardState[i][0], b: boardState[i][1], c: boardState[i][2]) {
                return (boardState[i][0], [(i, 0), (i, 1), (i, 2)]) // Row win
            }
            if checkLine(a: boardState[0][i], b: boardState[1][i], c: boardState[2][i]) {
                return (boardState[0][i], [(0, i), (1, i), (2, i)]) // Column win
            }
        }
        // Check diagonals
        if checkLine(a: boardState[0][0], b: boardState[1][1], c: boardState[2][2]) {
            return (boardState[0][0], [(0, 0), (1, 1), (2, 2)]) // Diagonal (top-left to bottom-right)
        }
        if checkLine(a: boardState[0][2], b: boardState[1][1], c: boardState[2][0]) {
            return (boardState[0][2], [(0, 2), (1, 1), (2, 0)]) // Diagonal (top-right to bottom-left)
        }
        return (0, nil) // No win
    }

    fileprivate func checkDraw() -> Bool {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if boardState[row][col] == 0 {
                    return false // Found an empty spot, so no draw yet
                }
            }
        }
        return true // No empty spots, it's a draw
    }

    func makeMove(row: Int, col: Int) {
        guard boardState[row][col] == 0 else { return }

        if let tile = board[row][col] {
            let label = SKLabelNode(text: currentPlayer.symbol)
            label.fontSize = tile.frame.size.height * 0.8  // Set font size relative to tile size
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: 0)  // Center the label
            tile.addChild(label)
        }
        
        boardState[row][col] = currentPlayer.rawValue

        let (winner, winCoordinates) = checkWin()
        if winner != 0 {
            print("Player \(currentPlayer.rawValue) wins!")
            if let winCoords = winCoordinates {
                drawWinningLine(winCoordinates: winCoords)
            }
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        }
        else if checkDraw() {
            print("It's a draw!")
            let delayAction = SKAction.wait(forDuration: 5.0)
            run(delayAction) {
                self.resetBoard()
            }
        }
        else {
            currentPlayer = currentPlayer.next
        }
    }

    fileprivate func drawWinningLine(winCoordinates: [(Int, Int)]) {
        guard let first = winCoordinates.first, let last = winCoordinates.last else { return }
        
        let startX = board[first.0][first.1]!.position.x
        let startY = board[first.0][first.1]!.position.y
        let endX = board[last.0][last.1]!.position.x
        let endY = board[last.0][last.1]!.position.y
        
        // Create a red line from start to end coordinates
        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: endX, y: endY))
        
        // Create the line node
        let line = SKShapeNode(path: path)
        line.strokeColor = NSColor.red
        line.lineWidth = 10.0
        
        // Add line to the scene
        addChild(line)
        winningLine = line // Store the line so it can be removed later
    }
}
