import SpriteKit
import AppKit

class GameScene: SKScene {
    fileprivate var board: [[SKSpriteNode?]] = [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
    fileprivate var boardState: [[Int]] = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
    fileprivate var currentPlayer = 1 // 1 for 'X', 2 for 'O'
    fileprivate var numColumns: CGFloat = 3

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
                    let row = coordinates[0]
                    let col = coordinates[1]
                    makeMove(row: row, col: col)
                }
            }
        }
    }
    
    override func didMove(to view: SKView) {
        drawBoard()
    }
    
    fileprivate func drawBoard() {
        let cellSize = min(size.width, size.height) / numColumns
        let boardWidth = cellSize * numColumns
        let boardHeight = cellSize * numColumns
        let xOffset = -boardWidth / 2
        let yOffset = -boardHeight / 2
        
        for row in 0..<3 {
            for col in 0..<3 {
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
        for row in 0..<3 {
            for col in 0..<3 {
                board[row][col]?.removeAllChildren()
                boardState[row][col] = 0
            }
        }
        currentPlayer = 1
    }
    
    fileprivate func checkWin() -> Int {
        // Check rows and columns
        for i in 0..<3 {
            if boardState[i][0] != 0 && boardState[i][0] == boardState[i][1] && boardState[i][1] == boardState[i][2] {
                return boardState[i][0]
            }
            if boardState[0][i] != 0 && boardState[0][i] == boardState[1][i] && boardState[1][i] == boardState[2][i] {
                return boardState[0][i]
            }
        }
        // Check diagonals
        if boardState[0][0] != 0 && boardState[0][0] == boardState[1][1] && boardState[1][1] == boardState[2][2] {
            return boardState[0][0]
        }
        if boardState[0][2] != 0 && boardState[0][2] == boardState[1][1] && boardState[1][1] == boardState[2][0] {
            return boardState[0][2]
        }
        return 0
    }
    
    func makeMove(row: Int, col: Int) {
        if boardState[row][col] == 0 {
            let symbol = currentPlayer == 1 ? "❌" : "⭕"
            let label = SKLabelNode(text: symbol)
            label.fontSize = 240
            board[row][col]?.addChild(label)
            boardState[row][col] = currentPlayer
            
            if let sound = NSSound(named: NSSound.Name("Pop")) {
                sound.play()
            }
            
            if checkWin() != 0 {
                print("Player \(currentPlayer) wins!")
                if let sound = NSSound(named: NSSound.Name("Glass")) {
                    sound.play()
                }
                resetBoard()
            } else {
                currentPlayer = currentPlayer == 1 ? 2 : 1
            }
        }
    }
}
