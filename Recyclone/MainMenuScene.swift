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
    var touchToNode = [UITouch: SKNode]()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.green
        
        let message = "Recyclone"
        
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        button.name = "btn"
        button.size.height = 100
        button.size.width = 100
        button.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 100)
        self.addChild(button)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let positionInScene = touch.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            // associate touches with the buttons they pressed
            if  touchedNode.name == "btn" &&
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
                    
                    let reveal = SKTransition.reveal(with: .down,
                                                     duration: 1)
                    let newScene = GameScene(size: view!.frame.size)
                    
                    scene?.view!.presentScene(newScene,
                                              transition: reveal)
                }
            }
        }
    }
    
}
