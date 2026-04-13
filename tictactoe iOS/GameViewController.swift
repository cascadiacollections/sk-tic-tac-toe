import UIKit
import SpriteKit
import os

@MainActor
class GameViewController: UIViewController {

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cascadiacollections.tictactoe",
        category: "GameViewController"
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else {
            Self.log.error("self.view is not an SKView — check storyboard")
            return
        }

        let viewSize = skView.bounds.size
        Self.log.debug("SKView bounds size: \(viewSize.width)x\(viewSize.height)")

        guard let scene = GameScene(size: viewSize) else {
            Self.log.error("Could not initialize GameScene")
            let alert = UIAlertController(title: "Error", message: "Could not start the game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }

    override var prefersStatusBarHidden: Bool { true }
}

