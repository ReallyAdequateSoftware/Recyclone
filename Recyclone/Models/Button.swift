//
//  Button.swift
//  Recyclone
//
//  Created by Evan Huang on 11/24/20.
//

import Foundation
import SpriteKit

class Button: SKShapeNode {
    private var label: SKLabelNode?
    private var unpressed: SKNode
    private var pressed: SKNode
    private var action: (() -> Void)?
    
    convenience init(label: String, location: CGPoint, unpressedImage: UIImage, pressedImage: UIImage, function: (() -> Void)? = nil) {
        self.init(rect: CGRect(origin: location,
                               size: unpressedImage.size))
        self.name = label
        self.isUserInteractionEnabled = true
        self.lineWidth = 0
        self.position = location
        self.action = function
        self.unpressed = SKSpriteNode(texture: SKTexture(image: unpressedImage))
        self.unpressed.name = label
        self.pressed = SKSpriteNode(texture: SKTexture(image: pressedImage))
        self.pressed.zPosition = ZPositions.foreground.rawValue
        self.pressed.name = label
        self.pressed.isHidden = true
        addChild(self.unpressed)
        addChild(self.pressed)
    }
    
    convenience init(label: String,
                     location: CGPoint,
                     unpressedColor: UIColor = LookAndFeel.currentColorScheme.unpressedButton,
                     pressedColor: UIColor = LookAndFeel.currentColorScheme.pressedButton,
                     textColor: UIColor = LookAndFeel.currentColorScheme.buttonText,
                     function: (() -> Void)? = nil) {
        
        //MARK init node for the label
        let labelNode = SKLabelNode(text: label)
        labelNode.fontName = LookAndFeel.fontScheme.buttonFontName
        labelNode.fontSize = LookAndFeel.fontScheme.buttonFontSize
        labelNode.fontColor = textColor
        labelNode.name = label
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = ZPositions.foreground.rawValue
        
        //MARK init constants for the button rectangle
        let buttonSize = labelNode.frame.size * 1.15
        let buttonRect = CGRect(origin: CGPoint(x: -buttonSize.width / 2,
                                                y: -buttonSize.height / 2),
                                size: buttonSize)
        
        self.init(rect: CGRect(origin: CGPoint(x: -buttonSize.width / 2,
                                                y: -buttonSize.height / 2),
                                size: buttonSize))
        
        self.position = location
        self.name = label
        self.isUserInteractionEnabled = true
        self.lineWidth = 0
        self.action = function
        self.label = labelNode

        self.pressed = SKShapeNode(rect: buttonRect,
                                   cornerRadius: 10)
        
        (self.pressed as! SKShapeNode).fillColor = pressedColor
        (self.pressed as! SKShapeNode).strokeColor = pressedColor
        self.pressed.name = label
        self.pressed.isHidden = true
        self.pressed.zPosition = ZPositions.behindForeground.rawValue
        
        self.unpressed = SKShapeNode(rect: buttonRect,
                                     cornerRadius: 10)
        (self.unpressed as! SKShapeNode).fillColor = unpressedColor
        (self.unpressed as! SKShapeNode).strokeColor = unpressedColor
        self.unpressed.name = label
        self.unpressed.zPosition = ZPositions.background.rawValue
        
        addChild(self.label!)
        addChild(self.unpressed)
        addChild(self.pressed)
    }
    
    override init() {
        self.pressed = SKShapeNode()
        self.unpressed = SKShapeNode()
        self.label = SKLabelNode()
        self.action = nil
        super.init()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        LookAndFeel.buttonFeedback.impactOccurred()
        LookAndFeel.audioScheme.buttonPress.play()
        self.pressed.isHidden = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        LookAndFeel.buttonFeedback.impactOccurred()
        LookAndFeel.audioScheme.buttonRelease.play()
        
        if self.action != nil{
            self.action!()
        }
        
        self.pressed.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
