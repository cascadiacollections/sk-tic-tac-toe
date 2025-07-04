import UIKit
import SpriteKit

@MainActor
class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let skView = view as? SKView {
            let viewSize = skView.bounds.size
            print("SKView bounds size: \(viewSize)")

            let scene = GameScene(size: viewSize)
            scene.scaleMode = SKSceneScaleMode.aspectFill
            skView.presentScene(scene)
            skView.ignoresSiblingOrder = true

            #if DEBUG
            skView.showsFPS = true
            skView.showsNodeCount = true
            #endif

        } else {
            print("ERROR: self.view is not an SKView. Check Storyboard or view setup.")
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }

    override var prefersStatusBarHidden: Bool { true }
}

