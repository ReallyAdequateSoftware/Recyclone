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
                     unpressedColor: UIColor = ColorScheme.currentColorClass.unpressedButton,
                     pressedColor: UIColor = ColorScheme.currentColorClass.pressedButton,
                     textColor: UIColor = ColorScheme.currentColorClass.buttonText,
                     function: (() -> Void)? = nil) {
        
        //MARK init node for the label
        let labelNode = LookAndFeel.textNode(text: label,
                                             as: FontScheme.button,
                                             color: textColor)
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = ZPositions.foreground.rawValue
        
        let BUTTON_PADDING_HEIGHT: CGFloat = 17
        let BUTTON_PADDING_WIDTH: CGFloat = 20

        let buttonSize = CGSize(width: labelNode.frame.size.width + BUTTON_PADDING_WIDTH,
                                height: labelNode.fontSize + BUTTON_PADDING_HEIGHT)
        let buttonRect = CGRect(origin: CGPoint(x: -buttonSize.width / 2,
                                                y: -buttonSize.height / 2),
                                size: buttonSize)
        
        self.init(rect: buttonRect)
        
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
        self.unpressed.zPosition = ZPositions.behindForeground.rawValue
        
        addChild(self.label!)
        addChild(self.unpressed)
        addChild(self.pressed)
    }
    
    override init() {
        self.pressed = SKShapeNode()
        self.unpressed = SKShapeNode()
        self.label = SKLabelNode()
        self.action = nil
        _ = LookAndFeel.audioScheme
        super.init()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        HapticFeedbackScheme.buttonFeedback.impactOccurred()
        LookAndFeel.audioScheme.buttonPress.play()
        self.pressed.isHidden = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        HapticFeedbackScheme.buttonFeedback.impactOccurred()
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
