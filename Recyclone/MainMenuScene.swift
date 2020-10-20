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
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // 1
        backgroundColor = SKColor.green
        
        // 2
        let message = "Recyclone"
        
        // 3
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
        /*
         run(SKAction.sequence([
         SKAction.wait(forDuration: 3.0),
         SKAction.run() { [weak self] in
         // 5
         guard let `self` = self else { return }
         let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
         let scene = GameScene(size: size)
         self.view?.presentScene(scene, transition:reveal)
         }
         ]))
         */
    }
    
    // 6
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let positionInScene = touch!.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name {
            if name == "btn" {
                
                let reveal = SKTransition.reveal(with: .down,
                                                 duration: 1)
                let newScene = GameScene(size: view!.frame.size)
                
                scene?.view!.presentScene(newScene,
                                        transition: reveal)
                
                
            }
        }
    }
}
