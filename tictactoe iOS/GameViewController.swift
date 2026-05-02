//
//  GameViewController.swift
//  tictactoe iOS
//
//  Created by Kevin T. Coughlin on 6/10/24.
//

import SpriteKit
import UIKit
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

        let scene: SKScene
        if let persisted = GamePersistence.load(),
           let restored = GameScene(size: viewSize, restoring: persisted) {
            // Skip the main menu and drop the player straight back into their game.
            Self.log.info("Restoring in-progress game — bypassing main menu")
            scene = restored
        } else {
            scene = MainMenuScene(size: viewSize)
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
