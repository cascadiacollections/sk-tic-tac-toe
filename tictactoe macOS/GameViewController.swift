//
//  GameViewController.swift
//  tictactoe macOS
//
//  Created by Kevin T. Coughlin on 6/10/24.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.init()
        let skView = self.view as! SKView

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}

