import SpriteKit
import AppKit

class GameScene: SKScene {
    fileprivate let boardSize = 3
    fileprivate var board: [[SKSpriteNode?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
    fileprivate var boardState: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 3)
    fileprivate var currentPlayer: Player = .x
    fileprivate var popSound: NSSound?
    fileprivate var winSound: NSSound?
    
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
        
        // Preload sounds to avoid creating them repeatedly
        popSound = NSSound(named: NSSound.Name("Pop"))
        winSound = NSSound(named: NSSound.Name("Glass"))
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
                if let label = board[row][col]?.childNode(withName: "label") as? SKLabelNode {
                    label.removeFromParent()  // Remove only labels
                }
                boardState[row][col] = 0
            }
        }
        currentPlayer = .x
    }

    fileprivate func checkLine(a: Int, b: Int, c: Int) -> Bool {
        return a != 0 && a == b && b == c
    }

    fileprivate func checkWin() -> Int {
        for i in 0..<boardSize {
            if checkLine(a: boardState[i][0], b: boardState[i][1], c: boardState[i][2]) {
                return boardState[i][0]
            }
            if checkLine(a: boardState[0][i], b: boardState[1][i], c: boardState[2][i]) {
                return boardState[0][i]
            }
        }
        if checkLine(a: boardState[0][0], b: boardState[1][1], c: boardState[2][2]) {
            return boardState[0][0]
        }
        if checkLine(a: boardState[0][2], b: boardState[1][1], c: boardState[2][0]) {
            return boardState[0][2]
        }
        return 0
    }

    func makeMove(row: Int, col: Int) {
        guard boardState[row][col] == 0 else { return }

        if let tile = board[row][col] {
            if let label = tile.childNode(withName: "label") as? SKLabelNode {
                label.text = currentPlayer.symbol  // Update the existing label
            } else {
                let label = SKLabelNode(text: currentPlayer.symbol)
                label.name = "label"
                label.fontSize = tile.frame.size.height * 0.8  // Set font size relative to tile size
                label.horizontalAlignmentMode = .center
                label.verticalAlignmentMode = .center
                label.position = CGPoint(x: 0, y: 0)  // Center the label
                tile.addChild(label)
            }
        }
        
        boardState[row][col] = currentPlayer.rawValue
        playSound(popSound)
        
        if checkWin() != 0 {
            print("Player \(currentPlayer.rawValue) wins!")
            playSound(winSound)
            resetBoard()
        } else {
            currentPlayer = currentPlayer.next
        }
    }

    fileprivate func playSound(_ sound: NSSound?) {
        guard let sound = sound else { return }
        if sound.isPlaying {
            sound.stop()
        }
        sound.play()
    }
}
