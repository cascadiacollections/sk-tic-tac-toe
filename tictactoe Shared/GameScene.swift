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
        boardNode = SKNode()
        addChild(boardNode)
        calculateBoardLayout()
        cellNodes = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        drawBoardGrid()
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
        cell.addChild(label)
    }

    private func checkGameState() {
        switch gameLogic.gameState {
        case .won(let winner):
            displayWinningLine(for: winner)
            displayGameOverMessage("Player \(winner.symbol) Wins!")
        case .draw:
            displayGameOverMessage("It's a Draw!")
        case .ongoing:
            break
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
        line.strokeColor = (player == .x ? GameColor.systemRed : GameColor.systemBlue).withAlphaComponent(0.8)
        line.lineWidth = cellSize * 0.15
        line.lineCap = .round
        line.zPosition = 1
        boardNode.addChild(line)
        winningLineNode = line
    }

    private func displayGameOverMessage(_ message: String) {
        let label = SKLabelNode(text: message)
        label.fontSize = size.height * 0.08
        label.fontColor = GameColor.label
        label.fontName = "HelveticaNeue-Bold"
        label.position = CGPoint(x: 0, y: size.height * 0.3)
        label.zPosition = 10
        label.name = "gameOverLabel"

        let bg = SKShapeNode(rect: label.frame.insetBy(dx: -20, dy: -10), cornerRadius: 10)
        bg.fillColor = GameColor.systemBackground.withAlphaComponent(0.85)
        bg.strokeColor = .clear
        bg.zPosition = 9
        bg.name = "gameOverBackground"
        addChild(bg)
        addChild(label)

        let sub = SKLabelNode(text: "Tap to play again")
        sub.fontSize = size.height * 0.04
        sub.fontColor = GameColor.secondaryLabel
        sub.fontName = "HelveticaNeue"
        sub.position = CGPoint(x: 0, y: label.position.y - label.frame.height - 10)
        sub.zPosition = 10
        sub.name = "resetLabel"
        addChild(sub)

        Self.log.info("Game over: \(message)")
    }

    // MARK: - Reset

    func resetGame() {
        gameLogic.reset()
        ["gameOverLabel", "gameOverBackground", "resetLabel"].forEach {
            childNode(withName: "//\($0)")?.removeFromParent()
        }
        winningLineNode?.removeFromParent()
        winningLineNode = nil

        for row in 0..<boardSize {
            for col in 0..<boardSize {
                cellNodes[row][col]?.removeAllChildren()
                if let cell = cellNodes[row][col] {
                    cell.addChild(makeCellBorderNode())
                }
            }
        }
        Self.log.info("Game reset")
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


