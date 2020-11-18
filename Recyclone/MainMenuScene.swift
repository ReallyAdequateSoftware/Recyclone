//
//  MainMenuScene.swift
//  Recyclone
//
//  Created by Michael Bodnar on 10/20/20.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    let button = SKSpriteNode(imageNamed: "compost_bin")
    var multiPeerButton = SKSpriteNode(color: .gray,
                                       size: CGSize(width: 200, height: 200))
    var touchToNode = [UITouch: SKNode]()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.systemBlue
        
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Recyclone"
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        button.name = "btn"
        button.size.height = 100
        button.size.width = 100
        button.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 100)
        self.addChild(button)
        
        multiPeerButton.name = "startMultipeer"
        multiPeerButton.position = CGPoint(x: 0, y: 0)
        self.addChild(multiPeerButton)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let positionInScene = touch.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            // associate touches with the buttons they pressed
            //TODO: use set to track button names
            if  (touchedNode.name == "btn" || touchedNode.name == "startMultipeer") &&
                    touchedNode.contains(positionInScene) {
                touchToNode.updateValue(touchedNode, forKey: touch)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            // if the touch started and ended on the same node, call the nodes action
            //TODO: write function that takes a node and returns an action to run when the node is pressed
            if let previouslyTouched = touchToNode[touch] {
                if previouslyTouched.contains(touch.location(in: self)) {
                    if previouslyTouched.name == "btn" {
                        let reveal = SKTransition.reveal(with: .down,
                                                         duration: 1)
                        let newScene = GameScene(size: view!.frame.size)
                        
                        scene?.view!.presentScene(newScene,
                                                  transition: reveal)
                    } else if previouslyTouched.name == "startMultipeer" {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "MultipeerViewController") as! MultipeerViewController
                        
                        vc.view.frame = (self.view?.frame)!
                        vc.view.layoutIfNeeded()

                        UIView.transition(with: self.view!, duration: 0.3, options: .transitionFlipFromRight, animations:
                                            {
                                                if let navVC = self.view!.window!.rootViewController as? UINavigationController {
                                                    navVC.pushViewController(vc, animated: true)
                                                }

                                            }, completion: { completed in

                                            })
                    }
                    
                }
            }
        }
    }
    
}
