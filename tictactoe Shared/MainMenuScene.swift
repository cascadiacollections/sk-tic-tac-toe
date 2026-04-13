import SpriteKit
import os

// MARK: - MainMenuScene

/// The app's landing scene. Presents a title and a list of board-size options;
/// selecting one transitions to a fresh `GameScene` for the chosen size.
///
/// This scene is bypassed when `GamePersistence.load()` returns an
/// in-progress game — see `GameViewController`.
@MainActor
final class MainMenuScene: SKScene {

    // MARK: - Configuration

    /// Board sizes offered on the menu.
    private static let offeredBoardSizes: [Int] = [3, 4, 5]

    // MARK: - State

    private var buttons: [(node: SKNode, boardSize: Int)] = []
    private var titleLabel: SKLabelNode?
    private var subtitleLabel: SKLabelNode?

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "MainMenuScene"
    )

    // MARK: - Initialization

    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        Self.log.debug("didMove size=\(self.size.width)x\(self.size.height)")
        buildMenu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size, !children.isEmpty else { return }
        buildMenu()
    }

    // MARK: - Layout

    private func buildMenu() {
        removeAllChildren()
        buttons.removeAll()
        titleLabel = nil
        subtitleLabel = nil

        let unit = min(size.width, size.height) / 10.0

        let title = SKLabelNode(text: "Tic Tac Toe")
        title.fontName = "HelveticaNeue-Bold"
        title.fontSize = unit * 1.25
        title.fontColor = GameColor.label
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: unit * 3.2)
        title.zPosition = 5
        addChild(title)
        titleLabel = title

        let subtitle = SKLabelNode(text: "Choose a board size")
        subtitle.fontName = "HelveticaNeue"
        subtitle.fontSize = unit * 0.55
        subtitle.fontColor = GameColor.secondaryLabel
        subtitle.verticalAlignmentMode = .center
        subtitle.horizontalAlignmentMode = .center
        subtitle.position = CGPoint(x: 0, y: unit * 2.1)
        subtitle.zPosition = 5
        addChild(subtitle)
        subtitleLabel = subtitle

        let buttonWidth = unit * 5.2
        let buttonHeight = unit * 1.3
        let spacing = unit * 0.35

        let sizes = Self.offeredBoardSizes
        let totalHeight = CGFloat(sizes.count) * buttonHeight + CGFloat(sizes.count - 1) * spacing
        var y = totalHeight / 2 - buttonHeight / 2

        for boardSize in sizes {
            let button = makeButton(
                title: "\(boardSize) × \(boardSize)",
                size: CGSize(width: buttonWidth, height: buttonHeight),
                fontSize: unit * 0.7
            )
            button.position = CGPoint(x: 0, y: y - unit * 0.2)
            addChild(button)
            buttons.append((button, boardSize))
            y -= buttonHeight + spacing
        }
    }

    private func makeButton(title: String, size: CGSize, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = "menuButton"
        container.zPosition = 10

        let background = SKShapeNode(
            rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height),
            cornerRadius: size.height * 0.22
        )
        background.fillColor = GameColor.systemGray6
        background.strokeColor = GameColor.systemGray3
        background.lineWidth = 2
        background.name = "menuButtonBackground"
        container.addChild(background)

        let label = SKLabelNode(text: title)
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = fontSize
        label.fontColor = GameColor.label
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "menuButtonLabel"
        container.addChild(label)

        return container
    }

    // MARK: - Input

#if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleSelection(at: touch.location(in: self))
    }
#elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        handleSelection(at: event.location(in: self))
    }
#endif

    private func handleSelection(at location: CGPoint) {
        guard let hit = buttons.first(where: { $0.node.calculateAccumulatedFrame().contains(location) }) else {
            return
        }
        Self.log.info("Menu selection: \(hit.boardSize)x\(hit.boardSize)")
        animateButton(hit.node) { [weak self] in
            self?.startGame(boardSize: hit.boardSize)
        }
    }

    private func animateButton(_ node: SKNode, completion: @escaping () -> Void) {
        let press = SKAction.scale(to: 0.94, duration: 0.06)
        let release = SKAction.scale(to: 1.0, duration: 0.08)
        node.run(.sequence([press, release]), completion: completion)
    }

    private func startGame(boardSize: Int) {
        guard let view else { return }
        // Starting a brand-new game — ensure no stale persisted state survives.
        GamePersistence.clear()
        guard let scene = GameScene(size: view.bounds.size, boardSize: boardSize) else {
            Self.log.error("Failed to create GameScene for boardSize=\(boardSize)")
            return
        }
        scene.scaleMode = .aspectFill
        view.presentScene(scene, transition: .fade(withDuration: 0.25))
    }
}
