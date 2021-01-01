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

class MainMenuScene: ItemAdderScene {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var startButton: Button!
    var multiPeerButton: Button!
    var sendDataButton: Button!
    var showLeaderboardButton: Button!
    var gcWranglerDelegate: GCWrangler?
        
    override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = ColorScheme.currentColorClass.menuBackground
        
        let title = LookAndFeel.textNode(text: "Recyclone",
                                         at: CGPoint(x: self.frame.midX,
                                                     y: self.frame.midY + 200),
                                         as: FontScheme.title,
                                         color: ColorScheme.currentColorClass.defaultText)
        addChild(title)
        
        let buttonNameToFunction = [("Start", startGame),
                                    ("Start Multipeer", startMultipeer),
                                    ("Send Data", sendData),
                                    ("Leaderboard", openLeaderboard)
                                    ]
        
        for (index, (name, function)) in buttonNameToFunction.enumerated() {
            let button = Button(label: name,
                                location: CGPoint(x: self.frame.midX,
                                                               y: self.frame.midY + 100 - CGFloat((index * 100))),
                                function: function)
            self.addChild(button)
        }
        
        self.itemLayer.zPosition = ZPositions.background.rawValue
        self.itemMovement.speed.value = -150
        
        

    }
    
    func startGame() -> Void {
        let reveal = SKTransition.crossFade(withDuration: TimeInterval(1.0))
        let gameScene = GameScene(size: self.size)
        gameScene.gcWranglerDelegate = self.gcWranglerDelegate
        cleanUp()
        self.scene?.view!.presentScene(gameScene, transition: reveal)
    }
    
    func startMultipeer() -> Void {
        let wrangler = self.appDelegate.multipeerWrangler
        wrangler?.startHosting()
        wrangler?.joinSession()
    }
    
    func sendData() -> Void{
        let wrangler = self.appDelegate.multipeerWrangler
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
    
    func openLeaderboard() {
        self.gcWranglerDelegate?.showLeaderboard()
    }
    
    deinit {
        print("main menu deinitialized")
    }
    
    override func cleanUp() {
        for child in self.children {
            print("clearing \(child)")
            child.removeAllActions()
            child.removeAllChildren()
            child.removeFromParent()
        }
        self.gcWranglerDelegate = nil
    }
    
    override func addItem(){
        //create a new item with a random texture
        if let randomItemTexture = trashItemTextures.randomElement(){
            let item = Item(itemTexture: randomItemTexture)
            item.name = randomItemTexture.type.rawValue
            item.position = CGPoint(x: random(min: item.size.width,
                                              max: SCREEN_WIDTH - item.size.width),
                                    y: SCREEN_HEIGHT + item.size.height)
            //set physics
            item.physicsBody?.velocity = CGVector(dx: 0,
                                                  dy: CGFloat(itemMovement.speed.value))
            item.alpha = 0.65
            
            itemLayer.addChild(item)
            print("\(item.name ?? "nothing") added")
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
}
