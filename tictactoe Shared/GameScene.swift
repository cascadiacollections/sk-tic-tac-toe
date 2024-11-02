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
    private var boardSize: Int
    private var gameLogic: GameLogic
    private var board: [[SKSpriteNode?]] = []

    init(boardSize: Int = 3) {
        self.boardSize = boardSize
        self.gameLogic = GameLogic(boardSize: boardSize)
        super.init(size: CGSize(width: 300, height: 300))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        drawBoard()
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
        
        // Calculate the board's origin based on centering
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        let xOffset = (size.width - boardWidth) / 2
        let yOffset = (size.height - boardHeight) / 2

        // Calculate the column and row based on the location of the touch
        let col = Int((location.x - xOffset) / cellSize)
        let row = Int((location.y - yOffset) / cellSize)

        // Ensure row and col are within bounds of the board
        guard row >= 0, row < boardSize, col >= 0, col < boardSize else { return }

        // Proceed if the move is valid in GameLogic
        if gameLogic.makeMove(row: row, col: col) {
            updateTile(row: row, col: col, player: gameLogic.currentPlayer)
            if case .won(let winner) = gameLogic.gameState {
                displayWinningLine(for: winner)
            }
        }
    }

    private func drawBoard() {
        let cellSize = min(size.width, size.height) / CGFloat(boardSize)
        
        // Calculate the total size of the board
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        
        // Offset to center the board within the scene
        let xOffset = (size.width - boardWidth) / 2
        let yOffset = (size.height - boardHeight) / 2
        
        for row in 0..<boardSize {
            var rowArray: [SKSpriteNode?] = []
            for col in 0..<boardSize {
                let cellNode = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
                cellNode.position = CGPoint(
                    x: xOffset + CGFloat(col) * cellSize + cellSize / 2,
                    y: yOffset + CGFloat(row) * cellSize + cellSize / 2
                )
                cellNode.name = "cell_\(row)_\(col)"
                addChild(cellNode)
                rowArray.append(cellNode)
                
                // Add a border to each cell
                let border = SKShapeNode(rect: CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize))
                border.strokeColor = GameColor.black
                border.lineWidth = 2
                cellNode.addChild(border)
            }
            board.append(rowArray)
        }
    }

    private func updateTile(row: Int, col: Int, player: GameLogic.Player) {
        guard let cellNode = board[row][col] else { return }
        
        let symbolLabel = SKLabelNode(text: player.symbol)
        symbolLabel.fontSize = min(size.width, size.height) / CGFloat(boardSize * 2)
        symbolLabel.fontColor = player == .x ? GameColor.red : GameColor.blue
        symbolLabel.verticalAlignmentMode = .center
        symbolLabel.horizontalAlignmentMode = .center
        symbolLabel.position = CGPoint(x: 0, y: 0)
        cellNode.addChild(symbolLabel)
    }

    private func displayWinningLine(for player: GameLogic.Player) {
        guard let winningPattern = gameLogic.getWinningPattern() else { return }
        
        let cellSize = min(size.width, size.height) / CGFloat(boardSize)
        let offset = -cellSize * CGFloat(boardSize) / 2
        
        // Ensure we have a valid start and end cell
        guard let startCell = winningPattern.first, let endCell = winningPattern.last else { return }
        
        // Helper function to calculate position based on row and column
        func position(forRow row: Int, col: Int) -> CGPoint {
            let x = offset + CGFloat(col) * cellSize + cellSize / 2
            let y = offset + CGFloat(row) * cellSize + cellSize / 2
            return CGPoint(x: x, y: y)
        }
        
        let startPosition = position(forRow: startCell.row, col: startCell.col)
        let endPosition = position(forRow: endCell.row, col: endCell.col)
        
        let linePath = CGMutablePath()
        linePath.move(to: startPosition)
        linePath.addLine(to: endPosition)
        
        let lineNode = SKShapeNode(path: linePath)
        lineNode.strokeColor = player == .x ? GameColor.red : GameColor.blue
        lineNode.lineWidth = 5
        
        // Optional: Add an animation for the winning line
        lineNode.alpha = 0
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        lineNode.run(fadeInAction)
        
        addChild(lineNode)
    }
}
