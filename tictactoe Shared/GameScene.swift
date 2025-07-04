import SpriteKit
import os.log // Use logging

#if os(iOS)
import UIKit
typealias GameColor = UIColor
typealias GameEvent = UIEvent // For touch/mouse event parameter consistency
typealias GameTouchEvent = UITouch
#elseif os(macOS)
import AppKit
typealias GameColor = NSColor
typealias GameEvent = NSEvent
typealias GameTouchEvent = NSEvent // macOS uses NSEvent directly for mouse down
#endif

// Logger for the scene
private let sceneLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.yourapp.tictactoe", category: "GameScene")

@MainActor
class GameScene: SKScene {

    // MARK: - Properties

    private let boardSize: Int
    private(set) var gameLogic: GameLogic
    private var boardNode: SKNode! // Node to hold all board elements for easy clearing/scaling
    private var cellNodes: [[SKSpriteNode?]] = [] // Store references to cell nodes if needed later
    private var winningLineNode: SKShapeNode? // Reference to the winning line to remove on reset

    private(set) var cellSize: CGFloat = 0
    private(set) var boardOriginOffset: CGPoint = .zero

    private var isGameOver: Bool {
        gameLogic.gameState != .ongoing
    }

    // MARK: - Initialization

    init?(boardSize: Int = 3, size: CGSize) {
        guard let logic = GameLogic(boardSize: boardSize) else {
            os_log(.error, log: sceneLog, "Failed to initialize GameLogic for board size %d", boardSize)
            return nil
        }
        self.boardSize = boardSize
        self.gameLogic = logic
        super.init(size: size)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.scaleMode = .aspectFill
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        let decodedBoardSize = aDecoder.decodeInteger(forKey: "boardSize")
        guard let logic = GameLogic(boardSize: decodedBoardSize > 0 ? decodedBoardSize : 3) else {
            fatalError("init(coder:) failed to initialize GameLogic")
        }
        self.boardSize = logic.boardSize
        self.gameLogic = logic
        super.init(coder: aDecoder)
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        os_log(.debug, log: sceneLog, "GameScene didMove to view. Size: %@", NSCoder.string(for: size))
        setupBoard()
    }

    // MARK: - Board Setup

    private func setupBoard() {
        children.forEach { $0.removeFromParent() }
        boardNode = SKNode()
        addChild(boardNode)

        calculateBoardLayout()

        cellNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

        drawBoardGrid()
    }

    private func calculateBoardLayout() {
        cellSize = min(size.width, size.height) * 0.9 / CGFloat(boardSize)
        os_log(.debug, log: sceneLog, "Calculated cell size: %.2f", cellSize)

        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)

        let xOffset = -boardWidth / 2
        let yOffset = -boardHeight / 2
        boardOriginOffset = CGPoint(x: xOffset, y: yOffset)

        os_log(.debug, log: sceneLog, "Board origin offset: %@", NSCoder.string(for: boardOriginOffset))
    }

    private func drawBoardGrid() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let cellPosition = position(forRow: row, col: col)

                let cellNode = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
                cellNode.position = cellPosition
                cellNode.name = "cell_\(row)_\(col)"
                boardNode.addChild(cellNode)
                cellNodes[row][col] = cellNode

                let border = SKShapeNode(rect: CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize), cornerRadius: cellSize * 0.05)
                border.strokeColor = GameColor.lightGray
                border.lineWidth = 1.5
                cellNode.addChild(border)
            }
        }
        os_log(.debug, log: sceneLog, "Board grid drawn.")
    }

    // MARK: - Coordinate Calculation Helper

    private func position(forRow row: Int, col: Int) -> CGPoint {
        let x = boardOriginOffset.x + CGFloat(col) * cellSize + cellSize / 2
        let y = boardOriginOffset.y + CGFloat(row) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    private func cellCoordinates(from location: CGPoint) -> (row: Int, col: Int)? {
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        let boardRect = CGRect(origin: boardOriginOffset, size: CGSize(width: boardWidth, height: boardHeight))

        guard boardRect.contains(location) else {
            os_log(.debug, log: sceneLog, "Touch location %@ outside board rect %@", NSCoder.string(for: location), NSCoder.string(for: boardRect))
            return nil
        }

        let col = Int((location.x - boardOriginOffset.x) / cellSize)
        let row = Int((location.y - boardOriginOffset.y) / cellSize)

        let clampedRow = max(0, min(row, boardSize - 1))
        let clampedCol = max(0, min(col, boardSize - 1))

        return (row: clampedRow, col: clampedCol)
    }

    // MARK: - Touch/Mouse Handling

    #if os(iOS)
    override func touchesBegan(_ touches: Set<GameTouchEvent>, with event: GameEvent?) {
        guard let touch = touches.first else { return }
        handleInteraction(at: touch.location(in: self))
    }
    #elseif os(macOS)
    override func mouseDown(with event: GameEvent) {
        handleInteraction(at: event.location(in: self))
    }
    #endif

    private func handleInteraction(at location: CGPoint) {
        os_log(.debug, log: sceneLog, "Interaction at: %@", NSCoder.string(for: location))

        if isGameOver {
            os_log(.debug, log: sceneLog, "Game is over. Handling game over tap.")
            handleGameOverTap()
            return
        }

        guard let (row, col) = cellCoordinates(from: location) else {
            os_log(.debug, log: sceneLog, "Interaction location does not map to a cell.")
            return
        }
        os_log(.debug, log: sceneLog, "Mapped interaction to cell: (%d, %d)", row, col)

        let playerMakingMove = gameLogic.currentPlayer

        let moveOutcome = gameLogic.makeMove(row: row, col: col)

        switch moveOutcome {
        case .success:
            os_log(.info, log: sceneLog, "Move successful for %{public}@ at (%d, %d)", playerMakingMove.symbol, row, col)
            updateTile(row: row, col: col, player: playerMakingMove)
            checkGameState()
        case .failure_positionTaken:
            os_log(.debug, log: sceneLog, "Move failed: Position (%d, %d) taken.", row, col)
        case .failure_invalidCoordinates:
            os_log(.error, log: sceneLog, "Move failed: Invalid coordinates (%d, %d) reported by logic, but interaction was mapped.", row, col)
        case .failure_gameAlreadyOver:
            os_log(.debug, log: sceneLog, "Move failed: Game already over, but check was bypassed?")
        }
    }

    // MARK: - Game State Updates

    private func updateTile(row: Int, col: Int, player: GameLogic.Player) {
        guard row >= 0, row < boardSize, col >= 0, col < boardSize,
              let cellNode = cellNodes[row][col] else {
            os_log(.error, log: sceneLog, "Attempted to update tile at invalid index (%d, %d)", row, col)
            return
        }

        let symbolLabel = SKLabelNode(text: player.symbol)
        symbolLabel.fontSize = cellSize * 0.6
        symbolLabel.fontColor = player == .x ? GameColor.red : GameColor.blue
        symbolLabel.fontName = "HelveticaNeue-Bold"
        symbolLabel.verticalAlignmentMode = .center
        symbolLabel.horizontalAlignmentMode = .center
        symbolLabel.position = CGPoint(x: 0, y: 0)
        cellNode.addChild(symbolLabel)
        os_log(.debug, log: sceneLog, "Updated tile (%d, %d) with symbol %{public}@", row, col, player.symbol)
    }

    private func checkGameState() {
        switch gameLogic.gameState {
        case .won(let winner):
            os_log(.info, log: sceneLog, "Game won by %{public}@", winner.symbol)
            displayWinningLine(for: winner)
            displayGameOverMessage("Player \(winner.symbol) Wins!")
        case .draw:
            os_log(.info, log: sceneLog, "Game ended in a draw.")
            displayGameOverMessage("It's a Draw!")
        case .ongoing:
            os_log(.debug, log: sceneLog, "Game ongoing. Next player: %{public}@", gameLogic.currentPlayer.symbol)
            break
        }
    }

    private func displayWinningLine(for player: GameLogic.Player) {
        winningLineNode?.removeFromParent()
        winningLineNode = nil

        guard let winningCoordinates = gameLogic.getWinningPatternCoordinates(),
              winningCoordinates.count == boardSize,
              let startCoord = winningCoordinates.first,
              let endCoord = winningCoordinates.last else {
            os_log(.error, log: sceneLog, "Could not get valid winning pattern coordinates for winner %{public}@", player.symbol)
            return
        }

        let startPosition = position(forRow: startCoord.row, col: startCoord.col)
        let endPosition = position(forRow: endCoord.row, col: endCoord.col)

        var adjustedStart = startPosition
        var adjustedEnd = endPosition
        let halfCell = cellSize / 2

        if startCoord.row == endCoord.row {
            adjustedStart.x -= halfCell
            adjustedEnd.x += halfCell
        } else if startCoord.col == endCoord.col {
            adjustedStart.y -= halfCell
            adjustedEnd.y += halfCell
        } else if (startCoord.row < endCoord.row && startCoord.col < endCoord.col) || (startCoord.row > endCoord.row && startCoord.col > endCoord.col) {
            if startCoord.row < endCoord.row {
                adjustedStart.x -= halfCell; adjustedStart.y -= halfCell
                adjustedEnd.x += halfCell; adjustedEnd.y += halfCell
            } else {
                adjustedStart.x += halfCell; adjustedStart.y += halfCell
                adjustedEnd.x -= halfCell; adjustedEnd.y -= halfCell
            }
        } else {
            if startCoord.row < endCoord.row {
                adjustedStart.x += halfCell; adjustedStart.y -= halfCell
                adjustedEnd.x -= halfCell; adjustedEnd.y += halfCell
            } else {
                adjustedStart.x -= halfCell; adjustedStart.y += halfCell
                adjustedEnd.x += halfCell; adjustedEnd.y -= halfCell
            }
        }

        let linePath = CGMutablePath()
        linePath.move(to: adjustedStart)
        linePath.addLine(to: adjustedEnd)

        let lineNode = SKShapeNode(path: linePath)
        lineNode.strokeColor = player == .x ? GameColor.red.withAlphaComponent(0.8) : GameColor.blue.withAlphaComponent(0.8)
        lineNode.lineWidth = cellSize * 0.15
        lineNode.lineCap = .round
        lineNode.zPosition = 1
        boardNode.addChild(lineNode)

        winningLineNode = lineNode
        os_log(.debug, log: sceneLog, "Displayed winning line from %@ to %@", NSCoder.string(for: adjustedStart), NSCoder.string(for: adjustedEnd))
    }

    private func displayGameOverMessage(_ message: String) {
        let messageLabel = SKLabelNode(text: message)
        messageLabel.fontSize = size.height * 0.08
        messageLabel.fontColor = GameColor.black
        messageLabel.fontName = "HelveticaNeue-Bold"
        messageLabel.position = CGPoint(x: 0, y: size.height * 0.3)
        messageLabel.zPosition = 10
        messageLabel.name = "gameOverLabel"

        let background = SKShapeNode(rect: messageLabel.frame.insetBy(dx: -20, dy: -10), cornerRadius: 10)
        background.fillColor = GameColor.white.withAlphaComponent(0.7)
        background.strokeColor = .clear
        background.zPosition = 9
        background.name = "gameOverBackground"
        addChild(background)

        addChild(messageLabel)
        os_log(.info, log: sceneLog, "Displayed game over message: '%{public}@'", message)

        let resetLabel = SKLabelNode(text: "Tap to play again")
        resetLabel.fontSize = size.height * 0.04
        resetLabel.fontColor = GameColor.darkGray
        resetLabel.fontName = "HelveticaNeue"
        resetLabel.position = CGPoint(x: 0, y: messageLabel.position.y - messageLabel.frame.height - 10)
        resetLabel.zPosition = 10
        resetLabel.name = "resetLabel"
        addChild(resetLabel)
    }

    // MARK: - Game Reset

    private func handleGameOverTap() {
        os_log(.info, log: sceneLog, "Game over tap detected. Resetting game.")
        resetGame()
    }

    func resetGame() {
        gameLogic.reset()

        removeNode(withName: "gameOverLabel")
        removeNode(withName: "gameOverBackground")
        removeNode(withName: "resetLabel")
        winningLineNode?.removeFromParent()
        winningLineNode = nil

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                cellNodes[row][col]?.removeAllChildren()
                let border = SKShapeNode(rect: CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize), cornerRadius: cellSize * 0.05)
                border.strokeColor = GameColor.lightGray
                border.lineWidth = 1.5
                cellNodes[row][col]?.addChild(border)
            }
        }

        os_log(.info, log: sceneLog, "Game has been reset.")
    }

    private func removeNode(withName name: String) {
        if let node = childNode(withName: "//\(name)") {
            node.removeFromParent()
        }
    }
}

