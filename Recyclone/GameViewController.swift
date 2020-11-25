//
//  GameViewController.swift
//  Recyclone
//
//  Created by Evan Huang on 9/28/20.
//

import UIKit
import SpriteKit
import GameplayKit
import GameKit

extension GameViewController: GCWrangler {
    func showLeaderboard() {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_ID
        present(gcVC, animated: true, completion: nil)
    }
}

class GameViewController: UIViewController, GKGameCenterControllerDelegate {
    
    /* Variables */
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID

         
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "com.highscore.Recyclone"
    	
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Call the GC authentication controller
        authenticateLocalPlayer()
        
        let scene = MainMenuScene(size: view.frame.size)
        scene.gcWranglerDelegate = self
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
    
    // MARK: - AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local
             
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                     
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                 
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error)
            }
        }
    }
    
    
    // Delegate to dismiss the GC controller
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
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
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
