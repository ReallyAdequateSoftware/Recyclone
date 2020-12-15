//
//  PauseScene.swift
//  Recyclone
//
//  Created by Evan Huang on 12/14/20.
//

import Foundation
import SpriteKit

class InGameMenuScene: SKScene {
    var gcWranglerDelegate: GCWrangler?
    var previousScene: GameScene?
    var gameOver: Bool = false
    let buttonLayer = SKNode()
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(size: CGSize, background: UIImage, gcWranglerDelegate: GCWrangler, previousScene: GameScene, gameOver: Bool) {
        self.init(size: size)
        self.gcWranglerDelegate = gcWranglerDelegate
        self.previousScene = previousScene
        self.gameOver = gameOver
        let blurredBackground = SKSpriteNode(texture: SKTexture(image: background))
        blurredBackground.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        blurredBackground.zPosition = ZPositions.background.rawValue
        self.addChild(blurredBackground)
    }
    override func didMove(to view: SKView) {
        
        initMenuButtons()
        
        self.addChild(buttonLayer)
    }
    
    func initMenuButtons() {
        
        //initialize "game over" buttons
        var buttonNameToFunction = [("Retry", retryGame),
                                ("Main Menu", goToMainMenu),
        ]
        if !gameOver {
            buttonNameToFunction.insert(("Resume", resumePlaying), at: 0)
        }
        let BUTTON_OFFSET = 100
        let TOTAL_OFFSET = BUTTON_OFFSET * (buttonNameToFunction.count - 1)
        let TOP_MOST_BUTTON_POSITION = self.frame.midY + CGFloat(TOTAL_OFFSET) * 0.5
        
        for (index, (name, function)) in buttonNameToFunction.enumerated() {
            let button = Button(label: name,
                                location: CGPoint(x: self.frame.midX,
                                                  y: TOP_MOST_BUTTON_POSITION - CGFloat(index * BUTTON_OFFSET)),
                                function: function)
            buttonLayer.addChild(button)
        }
        buttonLayer.zPosition = ZPositions.foreground.rawValue
    }
    
    func resumePlaying() {
        let animation = SKTransition.crossFade(withDuration: TimeInterval(1.0))
        self.view?.presentScene(previousScene!, transition: animation)
    }
    
    func retryGame() -> Void {
        let nextScene = GameScene(size: self.size)
        nextScene.gcWranglerDelegate = self.gcWranglerDelegate
        nextScene.scaleMode = self.scaleMode
        let animation = SKTransition.crossFade(withDuration: TimeInterval(1.0))
        //cleanUp()
        self.view?.presentScene(nextScene, transition: animation)
    }
    
    func goToMainMenu() -> Void {
        let nextScene = MainMenuScene(size: self.size)
        // TODO: seems like bad practice to manually set delegate rather than in an init somewhere
        nextScene.gcWranglerDelegate = self.gcWranglerDelegate
        nextScene.scaleMode = self.scaleMode
        let animation = SKTransition.crossFade(withDuration: TimeInterval(1.0))
        //cleanUp()
        self.view?.presentScene(nextScene, transition: animation)
    }
}

