//
//  GameViewController.swift
//  tictactoe macOS
//
//  Created by Kevin T. Coughlin on 6/10/24.
//

import Cocoa
import SpriteKit
import GameplayKit
import Foundation

enum DevTools {
    static func run(_ block: () -> Void) {
        #if DEBUG
        block()
        #endif
    }
}

class GameViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.init(boardSize: 3, size: view.bounds.size)
        let skView = self.view as! SKView

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true

        DevTools.run {
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsPhysics = true
        }
    }
}
