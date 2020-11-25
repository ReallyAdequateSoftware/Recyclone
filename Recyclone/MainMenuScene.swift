//
//  MainMenuScene.swift
//  Recyclone
//
//  Created by Michael Bodnar on 10/20/20.
//

import Foundation
import SpriteKit

func  *(left: CGSize, right: Double) -> CGSize {
    return CGSize(width: Double(left.width) * right, height: Double(left.height) * (right * 1.5))
}

protocol GCWrangler {
    func showLeaderboard()
}

class MainMenuScene: SKScene {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var startButton: Button!
    var multiPeerButton: Button!
    var sendDataButton: Button!
    var showLeaderboardButton: Button!
    var touchToNode = [UITouch: SKNode]()
    var buttonNames = Set<String>()
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    var gcWranglerDelegate: GCWrangler?
        
    override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = SKColor.systemBlue
        
        let label = SKLabelNode(text: "Recyclone")
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 200)
        addChild(label)
        
        
        startButton = Button(label: "Start", location: CGPoint(x: self.frame.midX, y: self.frame.midY))
        self.addChild(startButton.shape)
        buttonNames.insert(startButton.name)
        
        multiPeerButton = Button(label: "Start Multipeer", location: CGPoint(x: self.frame.midX, y: self.frame.midY - 100))
        self.addChild(multiPeerButton.shape)
        buttonNames.insert(multiPeerButton.name)
        
        sendDataButton = Button(label: "Send Data", location: CGPoint(x: self.frame.midX, y: self.frame.midY - 200))
        self.addChild(sendDataButton.shape)
        buttonNames.insert(sendDataButton.name)
        
        showLeaderboardButton = Button(label: "Leaderboard", location: CGPoint(x: self.frame.midX, y: self.frame.midY - 300))
        self.addChild(showLeaderboardButton.shape)
        buttonNames.insert(showLeaderboardButton.name)

    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        impactFeedback.prepare()
        
        for touch in touches {
            
            let positionInScene = touch.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            // associate touches with the buttons they pressed
            if  buttonNames.contains(touchedNode.name ?? "no name") &&
                    touchedNode.contains(positionInScene) {
                impactFeedback.impactOccurred()
                touchToNode.updateValue(touchedNode, forKey: touch)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        impactFeedback.prepare()
        
        for touch in touches {
            // if the touch started and ended on the same node, call the nodes action
            //TODO: write function that takes a node and returns an action to run when the node is pressed
            if let previouslyTouched = touchToNode[touch] {
                if previouslyTouched.contains(touch.location(in: self)) {
                    if previouslyTouched.name == "Start" {
                        
                        let reveal = SKTransition.crossFade(withDuration: TimeInterval(1.0))
                        let gameScene = GameScene(size: self.size)
                        self.scene?.view!.presentScene(gameScene, transition: reveal)
                        
                    } else if previouslyTouched.name == "Start Multipeer" {
                        var wrangler = self.appDelegate.multipeerWrangler
                        wrangler?.startHosting()
                        wrangler?.joinSession()
                        
                    } else if previouslyTouched.name == "Send Data" {
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
                    } else if previouslyTouched.name == "Leaderboard" {
                        self.gcWranglerDelegate?.showLeaderboard()
                    }
                    impactFeedback.impactOccurred()

                }
            }
        }
    }
    
}
