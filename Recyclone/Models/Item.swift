//
//  Item.swift
//  Recyclone
//
//  Created by Evan Huang on 11/25/20.
//

import Foundation
import SpriteKit
import GameplayKit

struct ItemTexture: Hashable{
    let texture: SKTexture
    let type: ItemType
}

enum ItemType: String {
    case recycle
    case trash
    case compost
    case none
}

class Item: SKSpriteNode{
    var itemTexture: ItemTexture
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        self.itemTexture = ItemTexture(texture: SKTexture(imageNamed: "not_found"), type: ItemType.none)
        super.init(texture: texture, color: color, size: size)
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width/2)
        self.physicsBody?.affectedByGravity = true
        self.physicsBody?.categoryBitMask = PhysicsCategory.item
        self.physicsBody?.contactTestBitMask = PhysicsCategory.boundary
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
        self.physicsBody?.isDynamic = true
        self.physicsBody?.linearDamping = 0
    }
    
    convenience init(itemTexture: ItemTexture) {
        self.init(texture: itemTexture.texture, color: UIColor.white, size: itemTexture.texture.size())
        self.itemTexture = itemTexture
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
