//
//  Button.swift
//  Recyclone
//
//  Created by Evan Huang on 11/24/20.
//

import Foundation
import SpriteKit

class Button {
    var shape: SKShapeNode
    var name: String

    init(label: String, location: CGPoint) {
        
        let labelNode = SKLabelNode(text: label)
        labelNode.fontColor = SKColor.lightGray
        labelNode.horizontalAlignmentMode = .center
        labelNode.position = location
        labelNode.name = label
        
        let buttonSize = labelNode.frame.size * 1.15
        self.shape = SKShapeNode(rect: CGRect(origin: CGPoint(x: labelNode.position.x - buttonSize.width / 2,
                                                              y: labelNode.position.y - buttonSize.height / 2),
                                              size: buttonSize),
                                            cornerRadius: 10)
        self.shape.fillColor = SKColor.darkGray
        self.shape.strokeColor = SKColor.darkGray
        self.shape.name = label
        
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        self.shape.addChild(labelNode)
        
        
        self.name = label
    }
}
