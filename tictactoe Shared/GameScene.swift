import SpriteKit
import os

// MARK: - Platform Abstractions

#if os(iOS)
import UIKit
typealias GameColor = UIColor
#elseif os(macOS)
import AppKit
typealias GameColor = NSColor
#endif

// MARK: - GameScene

@MainActor
class GameScene: SKScene {

    // MARK: - Properties

    private(set) var boardNode: SKNode!
    private(set) var cellNodes: [[SKSpriteNode?]] = []
    private(set) var winningLineNode: SKShapeNode?

    private let boardSize: Int
    private(set) var gameLogic: GameLogic

    private(set) var cellSize: CGFloat = 0
    private(set) var boardOriginOffset: CGPoint = .zero

    private var isGameOver: Bool { gameLogic.gameState != .ongoing }

    // Session scores — persist across resets within the same scene instance
    private var xWins = 0
    private var oWins = 0
    private var draws = 0

    // HUD nodes
    private var turnIndicatorLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "GameScene"
    )

    // MARK: - Initialization

    init?(boardSize: Int = 3, size: CGSize) {
        guard let logic = GameLogic(boardSize: boardSize) else {
            Self.log.error("Failed to init GameLogic for boardSize=\(boardSize)")
            return nil
        }
        self.boardSize = boardSize
        self.gameLogic = logic
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .aspectFill
        backgroundColor = .clear
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

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        Self.log.debug("didMove size=\(self.size.width)x\(self.size.height)")
        setupBoard()
    }

    // MARK: - Board Setup

    private func setupBoard() {
        children.forEach { $0.removeFromParent() }
        turnIndicatorLabel = nil
        scoreLabel = nil

        boardNode = SKNode()
        boardNode.alpha = 0
        addChild(boardNode)

        calculateBoardLayout()
        cellNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        drawBoardGrid()
        setupHUD()

        boardNode.run(.fadeIn(withDuration: 0.3))
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

        updateHUD()
    }

    private func updateHUD() {
        switch gameLogic.gameState {
        case .ongoing:
            let p = gameLogic.currentPlayer
            turnIndicatorLabel?.text = "\(p.symbol)  \(p == .x ? "X" : "O")'s turn"
            turnIndicatorLabel?.fontColor = p == .x ? GameColor.systemRed : GameColor.systemBlue
            turnIndicatorLabel?.isHidden = false
        case .won, .draw:
            turnIndicatorLabel?.isHidden = true
        }
        scoreLabel?.text = "❌ \(xWins)   ·   🤝 \(draws)   ·   ⭕ \(oWins)"
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
        if isGameOver { resetGame(); return }
        guard let (row, col) = cellCoordinates(from: location) else { return }
        let mover = gameLogic.currentPlayer
        switch gameLogic.makeMove(row: row, col: col) {
        case .success:
            Self.log.info("Move \(mover.symbol) at (\(row), \(col))")
            updateTile(row: row, col: col, player: mover)
            checkGameState()
        case .failure_positionTaken:
            Self.log.debug("Cell (\(row), \(col)) already taken")
            animateCellShake(row: row, col: col)
        case .failure_invalidCoordinates:
            Self.log.error("Invalid coords (\(row), \(col)) reached handleInteraction")
        case .failure_gameAlreadyOver:
            Self.log.debug("Move attempted after game ended")
        }
    }

    // MARK: - Rendering

    private func updateTile(row: Int, col: Int, player: Player) {
        guard let cellOpt = cellNodes[safe: row]?[safe: col],
              let cell = cellOpt else { return }
        let label = SKLabelNode(text: player.symbol)
        label.fontSize = cellSize * 0.6
        label.fontColor = player == .x ? GameColor.systemRed : GameColor.systemBlue
        label.fontName = "HelveticaNeue-Bold"
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.setScale(0)
        cell.addChild(label)
        label.run(.sequence([
            .scale(to: 1.2, duration: 0.10),
            .scale(to: 1.0, duration: 0.08)
        ]))
    }

    private func checkGameState() {
        switch gameLogic.gameState {
        case .won(let winner):
            if winner == .x { xWins += 1 } else { oWins += 1 }
            displayWinningLine(for: winner)
            displayGameOverMessage("\(winner.symbol)  \(winner == .x ? "X" : "O") Wins!")
            updateHUD()
        case .draw:
            draws += 1
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

    private func displayGameOverMessage(_ message: String) {
        let container = SKNode()
        container.name = "gameOverContainer"
        container.zPosition = 9
        container.alpha = 0

        let targetY: CGFloat = cellSize * CGFloat(boardSize) / 2 + cellSize * 1.05

        let label = SKLabelNode(text: message)
        label.fontSize = cellSize * 0.42
        label.fontColor = GameColor.label
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
        childNode(withName: "//gameOverContainer")?.run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
        winningLineNode?.run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
        winningLineNode = nil

        // Animate symbols out, then rebuild cell contents
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
            self.gameLogic.reset()
            for row in 0..<self.boardSize {
                for col in 0..<self.boardSize {
                    guard let cellOpt = self.cellNodes[safe: row]?[safe: col],
                          let cell = cellOpt else { continue }
                    cell.removeAllChildren()
                    cell.addChild(self.makeCellBorderNode())
                }
            }
            self.updateHUD()
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
        border.strokeColor = GameColor.separator
        border.lineWidth = 1.5
        return border
    }
}

// MARK: - Collection safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


