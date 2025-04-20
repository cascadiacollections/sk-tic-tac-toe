import UIKit
import SpriteKit
// import GameplayKit // No longer strictly needed if you're not using GK entities/components directly here

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Safely get the SKView
        // Use 'if let' and optional casting 'as?' for safety
        if let skView = self.view as? SKView {

            // 2. Get the size AFTER the view is loaded
            let viewSize = skView.bounds.size
            print("SKView bounds size: \(viewSize)") // Good for debugging

            // 3. Attempt to initialize the failable GameScene initializer
            if let scene = GameScene(boardSize: 3, size: viewSize) {
                // Initialization successful

                // 4. Configure the scene (optional, but good practice)
                // Set the scale mode to scale to fit the window while preserving aspect ratio
                scene.scaleMode = .aspectFill // or .aspectFit depending on preference

                // 5. Present the scene
                skView.presentScene(scene)

                // Configure the view (after presenting the scene is fine)
                skView.ignoresSiblingOrder = true // Performance optimization

                // Show debug info only during development
                #if DEBUG
                skView.showsFPS = true
                skView.showsNodeCount = true
                #endif

            } else {
                // Initialization failed (e.g., invalid board size passed to GameLogic)
                print("ERROR: Could not initialize GameScene. Check GameLogic initialization.")
                // Optionally, display an error message to the user here
                let alert = UIAlertController(title: "Error", message: "Could not start the game.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            print("ERROR: self.view is not an SKView. Check Storyboard or view setup.")
            // Handle the case where the main view isn't an SKView
        }
    }

    // --- These methods seem fine ---

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Allow landscape too if your scene handles rotation, otherwise just portrait
            return .allButUpsideDown
            // return .portrait
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
