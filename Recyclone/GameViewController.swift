//
//  GameViewController.swift
//  Recyclone
//
//  Created by Evan Huang on 9/28/20.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let scene = MainMenuScene(size: view.frame.size)
        print(view.bounds.size.height)
        print(view.bounds.size.height)
        print(view.frame.size)

        let skView = view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
         
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // make the nav bar disappear when we go back to the main menu
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
