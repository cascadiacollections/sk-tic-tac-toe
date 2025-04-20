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

class GameScene: SKScene {

    // MARK: - Properties

    private let boardSize: Int
    private var gameLogic: GameLogic
    private var boardNode: SKNode! // Node to hold all board elements for easy clearing/scaling
    private var cellNodes: [[SKSpriteNode?]] = [] // Store references to cell nodes if needed later
    private var winningLineNode: SKShapeNode? // Reference to the winning line to remove on reset

    private var cellSize: CGFloat = 0
    private var boardOriginOffset: CGPoint = .zero // Offset from scene origin (0,0) to board bottom-left

    private var isGameOver: Bool {
        gameLogic.gameState != .ongoing
    }

    // MARK: - Initialization

    init?(boardSize: Int = 3, size: CGSize) {
        // Ensure GameLogic can be initialized
        guard let logic = GameLogic(boardSize: boardSize) else {
            os_log(.error, log: sceneLog, "Failed to initialize GameLogic for board size %d", boardSize)
            return nil // Propagate initialization failure
        }
        self.boardSize = boardSize
        self.gameLogic = logic

        // Call the superclass initializer FIRST
        super.init(size: size) // <-- Call super.init here
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Explicitly set anchor point to the center
        self.scaleMode = .aspectFill
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        // If loaded from SKScene file, try to decode boardSize or use default
        // This requires encoding boardSize when saving the scene file.
        // For simplicity here, we keep the fatalError or default.
        let decodedBoardSize = aDecoder.decodeInteger(forKey: "boardSize")
        guard let logic = GameLogic(boardSize: decodedBoardSize > 0 ? decodedBoardSize : 3) else {
            fatalError("init(coder:) failed to initialize GameLogic")
        }
        self.boardSize = logic.boardSize
        self.gameLogic = logic
        super.init(coder: aDecoder)
        // Need to reconstruct board elements if loaded this way
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        os_log(.debug, log: sceneLog, "GameScene didMove to view. Size: %@", NSCoder.string(for: size))
        setupBoard()
    }

    // MARK: - Board Setup

    private func setupBoard() {
        // Clear existing board elements if any (e.g., on resize or reset)
        children.forEach { $0.removeFromParent() } // Clear all scene children first
        boardNode = SKNode() // Create a fresh parent node for the board
        addChild(boardNode)

        calculateBoardLayout() // Calculate size and offset based on current scene size

        // Pre-initialize the cell storage array
        cellNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)

        drawBoardGrid()
    }

    private func calculateBoardLayout() {
        // Determine cell size based on the smaller dimension and board size
        cellSize = min(size.width, size.height) * 0.9 / CGFloat(boardSize) // Use 90% of space
        os_log(.debug, log: sceneLog, "Calculated cell size: %.2f", cellSize)

        // Calculate the total size of the board
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)

        // Offset to center the board within the scene
        // Assumes anchorPoint is (0.5, 0.5) - default for scenes created in code
        // If anchorPoint is (0,0), adjust accordingly:
        // let xOffset = (size.width - boardWidth) / 2
        // let yOffset = (size.height - boardHeight) / 2
        // boardOriginOffset = CGPoint(x: xOffset, y: yOffset)

        // For anchorPoint (0.5, 0.5), the center is (0,0). Board origin is offset from center.
        let xOffset = -boardWidth / 2
        let yOffset = -boardHeight / 2
        boardOriginOffset = CGPoint(x: xOffset, y: yOffset)

        os_log(.debug, log: sceneLog, "Board origin offset: %@", NSCoder.string(for: boardOriginOffset))
    }

    private func drawBoardGrid() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let cellPosition = position(forRow: row, col: col)

                // Optional: Create a background node for the cell (easier to manage touches)
                let cellNode = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
                cellNode.position = cellPosition
                cellNode.name = "cell_\(row)_\(col)" // For potential lookup
                boardNode.addChild(cellNode)
                cellNodes[row][col] = cellNode // Store reference

                // Add a border to each cell
                let border = SKShapeNode(rect: CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize), cornerRadius: cellSize * 0.05) // Slight rounding
                border.strokeColor = GameColor.lightGray
                border.lineWidth = 1.5
                cellNode.addChild(border)
            }
        }
         os_log(.debug, log: sceneLog, "Board grid drawn.")
    }

    // MARK: - Coordinate Calculation Helper

    /// Calculates the center position of a cell in scene coordinates.
    private func position(forRow row: Int, col: Int) -> CGPoint {
        // Assumes boardOriginOffset and cellSize have been calculated
        let x = boardOriginOffset.x + CGFloat(col) * cellSize + cellSize / 2
        let y = boardOriginOffset.y + CGFloat(row) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    /// Calculates the row and column from a point in scene coordinates.
    private func cellCoordinates(from location: CGPoint) -> (row: Int, col: Int)? {
        // Check if the touch is within the board bounds first
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        let boardRect = CGRect(origin: boardOriginOffset, size: CGSize(width: boardWidth, height: boardHeight))

        guard boardRect.contains(location) else {
            os_log(.debug, log: sceneLog, "Touch location %@ outside board rect %@", NSCoder.string(for: location), NSCoder.string(for: boardRect))
            return nil // Touch outside the board area
        }

        // Calculate column and row based on the location relative to the board origin
        let col = Int((location.x - boardOriginOffset.x) / cellSize)
        let row = Int((location.y - boardOriginOffset.y) / cellSize)

        // Clamp values just in case of floating point inaccuracies at the edges
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
            return // Tap was outside the board grid
        }
         os_log(.debug, log: sceneLog, "Mapped interaction to cell: (%d, %d)", row, col)

        let playerMakingMove = gameLogic.currentPlayer // ** Capture player BEFORE move **

        let moveOutcome = gameLogic.makeMove(row: row, col: col)

        switch moveOutcome {
        case .success:
             os_log(.info, log: sceneLog, "Move successful for %{public}@ at (%d, %d)", playerMakingMove.symbol, row, col)
            updateTile(row: row, col: col, player: playerMakingMove) // ** Use captured player **
            checkGameState()
        case .failure_positionTaken:
             os_log(.debug, log: sceneLog, "Move failed: Position (%d, %d) taken.", row, col)
            // Optional: Add visual feedback like shaking the cell
        case .failure_invalidCoordinates:
            // Should not happen if cellCoordinates logic is correct, but log just in case
            os_log(.error, log: sceneLog, "Move failed: Invalid coordinates (%d, %d) reported by logic, but interaction was mapped.", row, col)
        case .failure_gameAlreadyOver:
            // Should be caught by the isGameOver check earlier, but good failsafe
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

        // Optional: Clear previous content if any (though shouldn't be needed with logic checks)
        // cellNode.removeAllChildren()
        // Add border back if cleared above

        let symbolLabel = SKLabelNode(text: player.symbol)
        symbolLabel.fontSize = cellSize * 0.6 // Adjust size relative to cell
        symbolLabel.fontColor = player == .x ? GameColor.red : GameColor.blue
        symbolLabel.fontName = "HelveticaNeue-Bold" // Example font
        symbolLabel.verticalAlignmentMode = .center
        symbolLabel.horizontalAlignmentMode = .center
        symbolLabel.position = CGPoint(x: 0, y: 0) // Center in the cell node
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
            // Game continues, no action needed here
            break
        }
    }

    private func displayWinningLine(for player: GameLogic.Player) {
        // Remove previous line if any
        winningLineNode?.removeFromParent()
        winningLineNode = nil

        // Obtain the winning pattern coordinates
        guard let winningCoordinates = gameLogic.getWinningPatternCoordinates(),
              winningCoordinates.count == boardSize, // Ensure we have the expected number of points
              let startCoord = winningCoordinates.first,
              let endCoord = winningCoordinates.last else {
            os_log(.error, log: sceneLog, "Could not get valid winning pattern coordinates for winner %{public}@", player.symbol)
            return
        }

        // Get start and end positions in scene coordinates (centers of the cells)
        let startPosition = position(forRow: startCoord.row, col: startCoord.col)
        let endPosition = position(forRow: endCoord.row, col: endCoord.col)

        // --- Adjust start/end points to extend to cell edges ---
        var adjustedStart = startPosition
        var adjustedEnd = endPosition
        let halfCell = cellSize / 2.0

        if startCoord.row == endCoord.row { // Horizontal win
            adjustedStart.x -= halfCell
            adjustedEnd.x += halfCell
        } else if startCoord.col == endCoord.col { // Vertical win
            adjustedStart.y -= halfCell
            adjustedEnd.y += halfCell
        } else if (startCoord.row < endCoord.row && startCoord.col < endCoord.col) || (startCoord.row > endCoord.row && startCoord.col > endCoord.col) { // Diagonal \
             // Check which corner is 'start' based on the sorted coordinates
            if startCoord.row < endCoord.row { // Top-Left to Bottom-Right
                adjustedStart.x -= halfCell; adjustedStart.y -= halfCell
                adjustedEnd.x += halfCell; adjustedEnd.y += halfCell
            } else { // Bottom-Right to Top-Left (shouldn't happen with sorting, but safe)
                adjustedStart.x += halfCell; adjustedStart.y += halfCell
                adjustedEnd.x -= halfCell; adjustedEnd.y -= halfCell
            }
        } else { // Diagonal /
            // Check which corner is 'start' based on the sorted coordinates
             if startCoord.row < endCoord.row { // Top-Right to Bottom-Left
                adjustedStart.x += halfCell; adjustedStart.y -= halfCell
                adjustedEnd.x -= halfCell; adjustedEnd.y += halfCell
            } else { // Bottom-Left to Top-Right (shouldn't happen with sorting, but safe)
                adjustedStart.x -= halfCell; adjustedStart.y += halfCell
                adjustedEnd.x += halfCell; adjustedEnd.y -= halfCell
            }
        }
        // --- End line extension ---


        // Create and style the winning line
        let linePath = CGMutablePath()
        linePath.move(to: adjustedStart)
        linePath.addLine(to: adjustedEnd)

        let lineNode = SKShapeNode(path: linePath)
        lineNode.strokeColor = player == .x ? GameColor.red.withAlphaComponent(0.8) : GameColor.blue.withAlphaComponent(0.8)
        lineNode.lineWidth = cellSize * 0.15 // Line width relative to cell size
        lineNode.lineCap = .round
        lineNode.zPosition = 1 // Ensure line is above symbols/grid
        boardNode.addChild(lineNode) // Add to board node

        winningLineNode = lineNode // Store reference
        os_log(.debug, log: sceneLog, "Displayed winning line from %@ to %@", NSCoder.string(for: adjustedStart), NSCoder.string(for: adjustedEnd))
    }

    private func displayGameOverMessage(_ message: String) {
        let messageLabel = SKLabelNode(text: message)
        messageLabel.fontSize = size.height * 0.08
        messageLabel.fontColor = GameColor.black
        messageLabel.fontName = "HelveticaNeue-Bold"
        messageLabel.position = CGPoint(x: 0, y: 0 + size.height * 0.3) // Position above the board
        messageLabel.zPosition = 10
        messageLabel.name = "gameOverLabel" // Name for easy removal

        // Optional: Add a semi-transparent background for the label
        let background = SKShapeNode(rect: messageLabel.frame.insetBy(dx: -20, dy: -10), cornerRadius: 10)
        background.fillColor = GameColor.white.withAlphaComponent(0.7)
        background.strokeColor = .clear
        background.zPosition = 9
        background.name = "gameOverBackground"
        addChild(background) // Add background behind label

        addChild(messageLabel) // Add label to the main scene (not boardNode)
        os_log(.info, log: sceneLog, "Displayed game over message: '%{public}@'", message)

         // Add a hint to reset
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
        // Called when tapping the screen after the game has ended
        os_log(.info, log: sceneLog, "Game over tap detected. Resetting game.")
        resetGame()
    }

    func resetGame() {
        gameLogic.reset()

        // Remove game over messages and winning line
        removeNode(withName: "gameOverLabel")
        removeNode(withName: "gameOverBackground")
        removeNode(withName: "resetLabel")
        winningLineNode?.removeFromParent()
        winningLineNode = nil

        // Clear symbols from cells
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                // Remove only the symbol label (child node), keep the cell background/border
                cellNodes[row][col]?.removeAllChildren()
                 // Re-add border if it was removed
                let border = SKShapeNode(rect: CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize), cornerRadius: cellSize * 0.05)
                border.strokeColor = GameColor.lightGray
                border.lineWidth = 1.5
                cellNodes[row][col]?.addChild(border)
            }
        }

        // Alternatively, just rebuild the whole board visually:
        // setupBoard() // This might be simpler if board setup is fast

        os_log(.info, log: sceneLog, "Game has been reset.")
    }

    private func removeNode(withName name: String) {
        if let node = childNode(withName: "//\(name)") { // Search entire scene graph
            node.removeFromParent()
        }
    }
}
