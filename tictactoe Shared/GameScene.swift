import SpriteKit
import os

// MARK: - Platform Abstractions

#if os(iOS)
import UIKit
typealias GameColor = UIColor
#elseif os(macOS)
import AppKit
typealias GameColor = NSColor

extension NSColor {
    static var label: NSColor { .labelColor }
    static var secondaryLabel: NSColor { .secondaryLabelColor }
    static var systemBackground: NSColor { .windowBackgroundColor }
    static var systemGray3: NSColor { .systemGray }
    static var systemGray6: NSColor { .controlBackgroundColor }
}
#endif

// MARK: - GameScene

@MainActor
class GameScene: SKScene {

    // MARK: - Properties

    private var boardNode: SKNode!
    private var cellNodes: [[SKSpriteNode?]] = []
    private var winningLineNode: SKShapeNode?

    private let boardSize: Int
    private var gameLogic: GameLogic

    private var cellSize: CGFloat = 0
    private var boardOriginOffset: CGPoint = .zero

    private var isGameOver: Bool { gameLogic.gameState != .ongoing }

    // Session scores — persist across resets within the same scene instance
    private var xWins = 0
    private var oWins = 0
    private var draws = 0
    private var isResetting = false

    // HUD nodes
    private var turnIndicatorLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var menuButtonNode: SKNode?
    private var undoButtonNode: SKNode?
    private var undoButtonLabel: SKLabelNode?

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "GameScene"
    )

    // MARK: - Initialization

    init?(size: CGSize, boardSize: Int = 3) {
        guard let logic = GameLogic(boardSize: boardSize) else {
            Self.log.error("Failed to init GameLogic for boardSize=\(boardSize)")
            return nil
        }
        self.boardSize = boardSize
        self.gameLogic = logic
        super.init(size: size)
        applySceneDefaults()
    }

    /// Creates a scene that restores a previously persisted in-progress game,
    /// including its session scores.
    init?(size: CGSize, restoring persisted: PersistedGame) {
        guard let logic = GameLogic.restored(from: persisted.snapshot) else {
            Self.log.error("Failed to restore GameLogic from snapshot")
            return nil
        }
        self.boardSize = logic.boardSize
        self.gameLogic = logic
        super.init(size: size)
        self.xWins = persisted.xWins
        self.oWins = persisted.oWins
        self.draws = persisted.draws
        applySceneDefaults()
    }

    required init?(coder aDecoder: NSCoder) {
        let decoded = aDecoder.decodeInteger(forKey: "boardSize")
        guard let logic = GameLogic(boardSize: decoded > 0 ? decoded : 3) else {
            fatalError("init(coder:) failed to create GameLogic")
        }
        boardSize = logic.boardSize
        gameLogic = logic
        super.init(coder: aDecoder)
    }

    private func applySceneDefaults() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        Self.log.debug("didMove size=\(self.size.width)x\(self.size.height)")
        setupBoard()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size, boardNode != nil else { return }
        setupBoard()
    }

    // MARK: - Board Setup

    private func setupBoard() {
        removeAllActions()
        children.forEach { $0.removeAllActions(); $0.removeFromParent() }
        turnIndicatorLabel = nil
        scoreLabel = nil
        menuButtonNode = nil
        undoButtonNode = nil
        undoButtonLabel = nil

        boardNode = SKNode()
        boardNode.alpha = 0
        addChild(boardNode)

        calculateBoardLayout()
        cellNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        drawBoardGrid()
        renderExistingMoves()
        setupHUD()

        boardNode.run(.fadeIn(withDuration: 0.3))
    }

    /// Renders any pieces already placed in the underlying `gameLogic`.
    /// Used when the scene is restored from a persisted snapshot.
    private func renderExistingMoves() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if let player = gameLogic.getPlayerAt(row: row, col: col) {
                    updateTile(row: row, col: col, player: player, animated: false)
                }
            }
        }
    }

    private func calculateBoardLayout() {
        cellSize = min(size.width, size.height) * 0.9 / CGFloat(boardSize)
        let boardDim = cellSize * CGFloat(boardSize)
        boardOriginOffset = CGPoint(x: -boardDim / 2, y: -boardDim / 2)
        Self.log.debug("cellSize=\(self.cellSize) origin=(\(self.boardOriginOffset.x), \(self.boardOriginOffset.y))")
    }

    private func drawBoardGrid() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let cell = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
                cell.position = position(forRow: row, col: col)
                cell.name = "cell_\(row)_\(col)"
                cell.isAccessibilityElement = true
                cell.accessibilityLabel = "Row \(row + 1), column \(col + 1), empty"
                cell.addChild(makeCellBorderNode())
                boardNode.addChild(cell)
                cellNodes[row][col] = cell
            }
        }
    }

    // MARK: - HUD

    private func setupHUD() {
        let boardDim = cellSize * CGFloat(boardSize)

        let indicator = SKLabelNode()
        indicator.fontName = "HelveticaNeue-Medium"
        indicator.fontSize = cellSize * 0.32
        indicator.position = CGPoint(x: 0, y: boardDim / 2 + cellSize * 0.42)
        indicator.verticalAlignmentMode = .center
        indicator.horizontalAlignmentMode = .center
        indicator.zPosition = 5
        indicator.name = "turnIndicator"
        addChild(indicator)
        turnIndicatorLabel = indicator

        let score = SKLabelNode()
        score.fontName = "HelveticaNeue"
        score.fontSize = cellSize * 0.22
        score.fontColor = GameColor.secondaryLabel
        score.position = CGPoint(x: 0, y: -(boardDim / 2 + cellSize * 0.38))
        score.verticalAlignmentMode = .center
        score.horizontalAlignmentMode = .center
        score.zPosition = 5
        score.name = "scoreLabel"
        addChild(score)
        scoreLabel = score

        setupMenuButton(boardDim: boardDim)
        setupUndoButton(boardDim: boardDim)

        updateHUD()
    }

    private func setupMenuButton(boardDim: CGFloat) {
        let buttonWidth = cellSize * 1.35
        let buttonHeight = cellSize * 0.48

        let (container, _) = makePillButton(
            title: "≡ Menu",
            name: "menuButton",
            size: CGSize(width: buttonWidth, height: buttonHeight)
        )
        container.position = CGPoint(
            x: -boardDim / 2 + buttonWidth / 2,
            y: boardDim / 2 + cellSize * 0.42
        )
        addChild(container)
        menuButtonNode = container
    }

    private func setupUndoButton(boardDim: CGFloat) {
        let buttonWidth = cellSize * 1.35
        let buttonHeight = cellSize * 0.48

        let (container, label) = makePillButton(
            title: "↶ Undo",
            name: "undoButton",
            size: CGSize(width: buttonWidth, height: buttonHeight)
        )
        container.position = CGPoint(
            x: boardDim / 2 - buttonWidth / 2,
            y: boardDim / 2 + cellSize * 0.42
        )
        addChild(container)
        undoButtonNode = container
        undoButtonLabel = label
    }

    /// Returns `true` when `location` (in scene coordinates) falls inside
    /// the fixed-size rect of a pill button built by `makePillButton`.
    private func pillButtonContains(_ button: SKNode, point location: CGPoint) -> Bool {
        guard let data = button.userData,
              let w = data["hitW"] as? CGFloat,
              let h = data["hitH"] as? CGFloat else {
            return button.calculateAccumulatedFrame().contains(location)
        }
        let origin = CGPoint(x: button.position.x - w / 2, y: button.position.y - h / 2)
        return CGRect(origin: origin, size: CGSize(width: w, height: h)).contains(location)
    }

    /// Factory for rounded HUD buttons. Returns the container and its label so
    /// callers can restyle the text (e.g. to show a disabled state).
    private func makePillButton(title: String, name: String, size: CGSize) -> (SKNode, SKLabelNode) {
        let container = SKNode()
        container.name = name
        container.zPosition = 6
        container.userData = ["hitW": size.width, "hitH": size.height]
        container.isAccessibilityElement = true
        container.accessibilityLabel = title

        let bg = SKShapeNode(
            rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height),
            cornerRadius: size.height * 0.3
        )
        bg.fillColor = GameColor.systemGray6
        bg.strokeColor = GameColor.systemGray3
        bg.lineWidth = 1.5
        container.addChild(bg)

        let label = SKLabelNode(text: title)
        label.fontName = "HelveticaNeue-Medium"
        label.fontSize = size.height * 0.45
        label.fontColor = GameColor.label
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        return (container, label)
    }

    private func updateHUD() {
        switch gameLogic.gameState {
        case .ongoing:
            let p = gameLogic.currentPlayer
            let letter = p == .x ? "X" : "O"
            turnIndicatorLabel?.text = "\(letter)'s turn"
            turnIndicatorLabel?.fontColor = p == .x ? GameColor.systemRed : GameColor.systemBlue
            turnIndicatorLabel?.isHidden = false
        case .won, .draw:
            turnIndicatorLabel?.isHidden = true
        }
        scoreLabel?.text = "X: \(xWins)   ·   Draws: \(draws)   ·   O: \(oWins)"

        // Dim the Undo button when there's nothing to undo.
        undoButtonNode?.alpha = gameLogic.canUndo ? 1.0 : 0.35
        undoButtonLabel?.fontColor = gameLogic.canUndo ? GameColor.label : GameColor.secondaryLabel
    }

    // MARK: - Coordinate Helpers

    private func position(forRow row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: boardOriginOffset.x + CGFloat(col) * cellSize + cellSize / 2,
            y: boardOriginOffset.y + CGFloat(row) * cellSize + cellSize / 2
        )
    }

    private func cellCoordinates(from location: CGPoint) -> (row: Int, col: Int)? {
        let boardDim = cellSize * CGFloat(boardSize)
        let boardRect = CGRect(origin: boardOriginOffset, size: CGSize(width: boardDim, height: boardDim))
        guard boardRect.contains(location) else { return nil }
        let col = max(0, min(Int((location.x - boardOriginOffset.x) / cellSize), boardSize - 1))
        let row = max(0, min(Int((location.y - boardOriginOffset.y) / cellSize), boardSize - 1))
        return (row, col)
    }

    // MARK: - Input Handling

#if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleInteraction(at: touch.location(in: self))
    }
#elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        handleInteraction(at: event.location(in: self))
    }
#endif

    private func handleInteraction(at location: CGPoint) {
        guard !isResetting else { return }

        // HUD buttons take precedence over any board interaction.
        if let menu = menuButtonNode, pillButtonContains(menu, point: location) {
            returnToMainMenu()
            return
        }
        if let undo = undoButtonNode, pillButtonContains(undo, point: location) {
            performUndo()
            return
        }

        if isGameOver { resetGame(); return }
        guard let (row, col) = cellCoordinates(from: location) else { return }
        let mover = gameLogic.currentPlayer
        switch gameLogic.makeMove(row: row, col: col) {
        case .success:
            Self.log.info("Move \(mover.symbol) at (\(row), \(col))")
            updateTile(row: row, col: col, player: mover)
            checkGameState()
            persistCurrentState()
        case .failurePositionTaken:
            Self.log.debug("Cell (\(row), \(col)) already taken")
            animateCellShake(row: row, col: col)
        case .failureInvalidCoordinates:
            Self.log.error("Invalid coords (\(row), \(col)) reached handleInteraction")
        case .failureGameAlreadyOver:
            Self.log.debug("Move attempted after game ended")
        }
    }

    // MARK: - Undo

    private func performUndo() {
        guard !isResetting, gameLogic.canUndo else { return }

        // Capture the terminal state *before* the undo clears it, so we know
        // whether to roll back a win or a draw from the session scores.
        let priorState = gameLogic.gameState
        guard let reverted = gameLogic.undo() else { return }
        Self.log.info("Undid \(reverted.player.symbol) at (\(reverted.row), \(reverted.col))")

        switch priorState {
        case .won(let winner):
            dismissGameOverUI()
            if winner == .x { xWins = max(0, xWins - 1) } else { oWins = max(0, oWins - 1) }
        case .draw:
            dismissGameOverUI()
            draws = max(0, draws - 1)
        case .ongoing:
            break
        }

        removeTile(row: reverted.row, col: reverted.col)
        StatsStore.rollBack(priorState)
        updateHUD()
        persistCurrentState()
    }

    private func dismissGameOverUI() {
        childNode(withName: "//gameOverContainer")?.removeFromParent()
        winningLineNode?.removeFromParent()
        winningLineNode = nil
    }

    private func removeTile(row: Int, col: Int) {
        guard let cellOpt = cellNodes[safe: row]?[safe: col], let cell = cellOpt else { return }
        cell.accessibilityLabel = "Row \(row + 1), column \(col + 1), empty"
        for child in cell.children where child is SKLabelNode {
            child.run(.sequence([
                .scale(to: 0, duration: 0.08),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Persistence

    /// Saves the current logical state when a game is in progress; clears the
    /// persisted slot once the game has ended so the next launch returns to
    /// the main menu.
    private func persistCurrentState() {
        guard gameLogic.gameState == .ongoing else {
            GamePersistence.clear()
            return
        }
        let persisted = PersistedGame(
            snapshot: gameLogic.snapshot(),
            xWins: xWins,
            oWins: oWins,
            draws: draws
        )
        GamePersistence.save(persisted)
    }

    // MARK: - Navigation

    private func returnToMainMenu() {
        Self.log.info("Returning to main menu")
        GamePersistence.clear()
        guard let view else { return }
        let menu = MainMenuScene(size: view.bounds.size)
        menu.scaleMode = .aspectFill
        view.presentScene(menu, transition: .fade(withDuration: 0.25))
    }

    // MARK: - Rendering

    private func updateTile(row: Int, col: Int, player: Player, animated: Bool = true) {
        guard let cellOpt = cellNodes[safe: row]?[safe: col],
              let cell = cellOpt else { return }
        let letter = player == .x ? "X" : "O"
        let label = SKLabelNode(text: letter)
        label.fontSize = cellSize * 0.55
        label.fontColor = player == .x ? GameColor.systemRed : GameColor.systemBlue
        label.fontName = "HelveticaNeue-Bold"
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.setScale(animated ? 0 : 1)
        cell.addChild(label)
        cell.accessibilityLabel = "Row \(row + 1), column \(col + 1), \(letter)"
        if animated {
            label.run(.sequence([
                .scale(to: 1.2, duration: 0.10),
                .scale(to: 1.0, duration: 0.08)
            ]))
        }
    }

    private func checkGameState() {
        switch gameLogic.gameState {
        case .won(let winner):
            if winner == .x { xWins += 1 } else { oWins += 1 }
            StatsStore.recordWin(for: winner)
            displayWinningLine(for: winner)
            displayGameOverMessage("\(winner == .x ? "X" : "O") Wins! 🎉", winner: winner)
            updateHUD()
        case .draw:
            draws += 1
            StatsStore.recordDraw()
            displayGameOverMessage("It's a Draw! 🤝")
            updateHUD()
        case .ongoing:
            updateHUD()
        }
    }

    private func displayWinningLine(for player: Player) {
        winningLineNode?.removeFromParent()
        winningLineNode = nil

        guard let coords = gameLogic.getWinningPatternCoordinates(),
              coords.count == boardSize,
              let first = coords.first, let last = coords.last else { return }

        var start = position(forRow: first.row, col: first.col)
        var end   = position(forRow: last.row,  col: last.col)
        let half  = cellSize / 2

        if first.row == last.row {
            start.x -= half; end.x += half
        } else if first.col == last.col {
            start.y -= half; end.y += half
        } else if (last.row - first.row) * (last.col - first.col) > 0 {
            start.x -= half; start.y -= half
            end.x   += half; end.y   += half
        } else {
            start.x += half; start.y -= half
            end.x   -= half; end.y   += half
        }

        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let line = SKShapeNode(path: path)
        line.strokeColor = (player == .x ? GameColor.systemRed : GameColor.systemBlue).withAlphaComponent(0.85)
        line.lineWidth = cellSize * 0.15
        line.lineCap = .round
        line.zPosition = 1
        line.alpha = 0
        boardNode.addChild(line)
        line.run(.fadeIn(withDuration: 0.25))
        winningLineNode = line
    }

    private func displayGameOverMessage(_ message: String, winner: Player? = nil) {
        let container = SKNode()
        container.name = "gameOverContainer"
        container.zPosition = 9
        container.alpha = 0

        let targetY: CGFloat = cellSize * CGFloat(boardSize) / 2 + cellSize * 1.05

        let label = SKLabelNode(text: message)
        label.fontSize = cellSize * 0.42
        label.fontColor = winner.map { $0 == .x ? GameColor.systemRed : GameColor.systemBlue } ?? GameColor.label
        label.fontName = "HelveticaNeue-Bold"
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        let bg = SKShapeNode(rect: label.frame.insetBy(dx: -16, dy: -10), cornerRadius: 10)
        bg.fillColor = GameColor.systemBackground.withAlphaComponent(0.88)
        bg.strokeColor = .clear
        bg.zPosition = -1
        container.addChild(bg)

        let sub = SKLabelNode(text: "Tap anywhere to play again")
        sub.fontSize = cellSize * 0.2
        sub.fontColor = GameColor.secondaryLabel
        sub.fontName = "HelveticaNeue"
        sub.verticalAlignmentMode = .center
        sub.horizontalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: -label.frame.height - 14)
        container.addChild(sub)

        container.position = CGPoint(x: 0, y: targetY - 12)
        addChild(container)

        container.run(.group([
            .fadeIn(withDuration: 0.22),
            .moveBy(x: 0, y: 12, duration: 0.22)
        ]))

        Self.log.info("Game over: \(message)")
    }

    // MARK: - Reset

    func resetGame() {
        guard !isResetting else { return }
        isResetting = true

        gameLogic.reset()
        // Starting a fresh round — nothing to restore until the next move.
        GamePersistence.clear()

        childNode(withName: "//gameOverContainer")?.run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
        if let line = winningLineNode {
            winningLineNode = nil
            line.run(.sequence([
                .fadeOut(withDuration: 0.15),
                .removeFromParent()
            ]))
        }

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                guard let cellOpt = cellNodes[safe: row]?[safe: col],
                      let cell = cellOpt else { continue }
                let symbolChildren = cell.children.filter { $0 is SKLabelNode }
                symbolChildren.forEach { node in
                    node.run(.sequence([
                        .scale(to: 0, duration: 0.12),
                        .removeFromParent()
                    ]))
                }
            }
        }

        run(.wait(forDuration: 0.18)) { [weak self] in
            guard let self else { return }
            for row in 0..<self.boardSize {
                for col in 0..<self.boardSize {
                    guard let cellOpt = self.cellNodes[safe: row]?[safe: col],
                          let cell = cellOpt else { continue }
                    cell.removeAllChildren()
                    cell.addChild(self.makeCellBorderNode())
                }
            }
            self.updateHUD()
            self.isResetting = false
        }

        Self.log.info("Game reset")
    }

    // MARK: - Animations

    private func animateCellShake(row: Int, col: Int) {
        guard let cellOpt = cellNodes[safe: row]?[safe: col],
              let cell = cellOpt else { return }
        cell.run(.sequence([
            .moveBy(x: -5, y: 0, duration: 0.04),
            .moveBy(x: 10, y: 0, duration: 0.04),
            .moveBy(x: -5, y: 0, duration: 0.04)
        ]))
    }

    // MARK: - Helpers

    private func makeCellBorderNode() -> SKShapeNode {
        let border = SKShapeNode(
            rect: CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize),
            cornerRadius: cellSize * 0.05
        )
        border.strokeColor = GameColor.systemGray3
        border.lineWidth = 2.5
        border.fillColor = GameColor.systemGray6
        return border
    }
}

// MARK: - Collection safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


