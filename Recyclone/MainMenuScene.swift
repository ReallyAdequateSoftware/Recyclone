//
//  MainMenuScene.swift
//  Recyclone
//
//  Created by Michael Bodnar on 10/20/20.
//

import Foundation
import SpriteKit

func  *(left: CGSize, right: Double) -> CGSize {
    return CGSize(width: Double(left.width) * right, height: Double(left.height) * right)
}

class MainMenuScene: SKScene {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let button = SKSpriteNode(imageNamed: "compost_bin")
    var multiPeerButtonText = SKLabelNode(text: "Start Multipeer")
    var multiPeerButtonShape = SKShapeNode()
    var sendDataButton = SKShapeNode()
    var touchToNode = [UITouch: SKNode]()
    var gameScene: GameScene?
    
    override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = SKColor.systemBlue
        gameScene = GameScene(size: size)
        
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
        
        let mpButtonLocation = CGPoint(x: self.frame.midX, y: 200)
        multiPeerButtonText.fontColor = SKColor.lightGray
        multiPeerButtonText.horizontalAlignmentMode = .center
        multiPeerButtonText.position = mpButtonLocation
        
        multiPeerButtonShape = SKShapeNode(rect: CGRect(origin: CGPoint(x: multiPeerButtonText.frame.origin.x / 1.15,
                                                                        y: multiPeerButtonText.frame.origin.y),
                                                        size: multiPeerButtonText.frame.size * 1.15),
                                           cornerRadius: 10)
        multiPeerButtonShape.fillColor = SKColor.darkGray
        multiPeerButtonShape.strokeColor = SKColor.darkGray
        multiPeerButtonShape.name = "startMultipeer"
        
        sendDataButton = SKShapeNode(circleOfRadius: 50)
        sendDataButton.position = CGPoint(x: self.frame.midX, y: 50)
        sendDataButton.fillColor = SKColor.darkGray
        sendDataButton.name = "sendData"
        self.addChild(sendDataButton)
        
        self.addChild(multiPeerButtonText)
        self.addChild(multiPeerButtonShape)
        
        
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
            if  (touchedNode.name == "btn" || touchedNode.name == "startMultipeer" || touchedNode.name == "sendData") &&
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
                        
                        self.scene?.view!.presentScene(self.gameScene!, transition: reveal)
                        
                    } else if previouslyTouched.name == "startMultipeer" {
                        var wrangler = self.appDelegate.multipeerWrangler
                        wrangler?.startHosting()
                        wrangler?.joinSession()
                        
                    } else if previouslyTouched.name == "sendData" {
                        var wrangler = self.appDelegate.multipeerWrangler
                        if let d = "test data".data(using: .utf8) {
                            do {
                                print("sending data to \(wrangler?.mcSession!.connectedPeers)")
                                try wrangler?.mcSession?.send(d as Data, toPeers: (wrangler?.mcSession!.connectedPeers)!, with: .reliable)
                            } catch {
                                print("error while sending")
                            }
                        }
                        
                        if let data = wrangler?.data {
                            
                            print("\(String(data: data, encoding: .utf8))")
                        }
                    }
                    
                }
            }
        }
    }
    
}
