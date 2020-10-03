//
//  GameScene.swift
//  Recyclone
//
//  Created by Evan Huang on 9/28/20.
//

import SpriteKit
import GameplayKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif


struct Item: Hashable{
    let texture: SKTexture
    let type: String
}

struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let boundary  : UInt32 = 0b1
    static let item      : UInt32 = 0b10
    
}
extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}


class GameScene: SKScene {
    
    var items = Set<Item>()
    var fallTime = 20
    var fallInterval = 1
    var difficulty = 1
    var itemsMissed = 0
    var score = 0
    var scoreNode = SKLabelNode()
    var itemsMissedNode = SKLabelNode()
    let NUM_OF_RECYCLE_IMG = 0
    let NUM_OF_COMPOST_IMG = 1
    let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    var compostBin = SKSpriteNode()
    var currentZ = 0
    let BOUNDARY_OUTSET = CGFloat(100)
    let FONT_SIZE = 30
    let FONT_NAME = "HelveticaNeue"
    
    //map for associating individual touches with items
    private var touchToNode = [UITouch: SKNode]()
    
    /*
     when view is loaded
     */
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.white
        //initialize trash item textures
        for i in 0..<NUM_OF_COMPOST_IMG{
            items.insert( Item(texture: SKTexture(imageNamed: "compost/compost\(i)"),
                               type: "compost"))
        }
        for i in 0..<NUM_OF_RECYCLE_IMG{
            items.insert( Item(texture: SKTexture(imageNamed: "recycle/recycle\(i)"),
                               type: "recycle"))
        }
        print(items)
        print("width: \(SCREEN_WIDTH)")
        print("height: \(SCREEN_HEIGHT)")
        
        //setup boundary removal physics for performance and game over mechanism
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeFrom: CGPoint(
                                        x: -BOUNDARY_OUTSET,
                                        y: -BOUNDARY_OUTSET),
                                    to: CGPoint(
                                        x: SCREEN_WIDTH + BOUNDARY_OUTSET,
                                        y: -BOUNDARY_OUTSET))
        physicsBody?.categoryBitMask = PhysicsCategory.boundary
        
        //setup scoring
        scoreNode.text = "\(score)"
        scoreNode.position = CGPoint(x: SCREEN_WIDTH * 0.25,
                                     y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        scoreNode.fontColor = UIColor.green
        scoreNode.fontSize = CGFloat(FONT_SIZE)
        scoreNode.fontName = FONT_NAME
        addChild(scoreNode)
        
        itemsMissedNode.text = "\(itemsMissed)"
        itemsMissedNode.position = CGPoint(x: SCREEN_WIDTH * 0.75,
                                           y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        itemsMissedNode.fontColor = UIColor.red
        itemsMissedNode.fontSize = CGFloat(FONT_SIZE)
        itemsMissedNode.fontName = FONT_NAME
        addChild(itemsMissedNode)
        
        //add scoring bins
        addBins()
        //add the items
        run(
            SKAction.repeatForever (
                SKAction.sequence([
                    SKAction.wait(forDuration: TimeInterval(1/difficulty)),
                    SKAction.run({
                        self.addItem()
                        if self.itemsMissed > 10 {
                            view.isPaused = true
                            self.removeAction(forKey: "New Thread")
                            //go to game over screen
                        }
                    })
                ])
            ),
            withKey: "New Thread"
        )
        
        //        run(SKAction.repeat(SKAction.sequence([
        //            SKAction.run(addItem),
        //            SKAction.wait(forDuration: 1)
        //        ]),
        //        count: 10))
    }
    
    /*
     HANDLE TOUCH EVENTS
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in: self)
            let touchedNodes = self.nodes(at: location)
            //reversed to select nodes that appear on top, first
            for node in touchedNodes.reversed(){
                if node.name == "compost" || node.name == "recycle"{
                    node.isPaused = true
                    self.touchToNode.updateValue(node, forKey: touch)
                    break
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            touchToNode[touch]?.position = touch.location(in: self)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            if let node = self.touchToNode[touch],
               (node.name == "compost"){
                if(compostBin.frame.contains(node.position)){
                    SCORE += 1
                    currentZ -= 1
                    scoreNode.text = "\(SCORE)"
                    node.removeFromParent()
                    
                }
            }
            self.touchToNode[touch]?.isPaused = false
            touchToNode.removeValue(forKey: touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            self.touchToNode[touch]?.isPaused = false
            touchToNode.removeValue(forKey: touch)
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    
    /*
     random number generation
     */
    func random() -> CGFloat{	
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max:CGFloat) -> CGFloat{
        return random() * (max-min) + min
    }
    
    /*
     add an item of trash onto the screen
     */
    func addItem(){
        //create a new item with a random texture
        let randomItem = items.randomElement()
        let item = SKSpriteNode(texture: randomItem?.texture)
        item.name = randomItem?.type
        item.position = CGPoint(x: random(min: 0,
                                          max: SCREEN_WIDTH - item.size.width),
                                y: random(min: SCREEN_HEIGHT,
                                          max: SCREEN_HEIGHT + item.position.y * 2))
        item.zPosition = CGFloat(currentZ)
        //set physics
        item.physicsBody = SKPhysicsBody(circleOfRadius: item.size.width/2)
        item.physicsBody?.affectedByGravity = false
        item.physicsBody?.categoryBitMask = PhysicsCategory.item
        item.physicsBody?.contactTestBitMask = PhysicsCategory.boundary
        item.physicsBody?.collisionBitMask = PhysicsCategory.none
        item.physicsBody?.isDynamic = true
        
        currentZ += 1
        addChild(item)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0,
                                                    dy: -(SCREEN_HEIGHT + item.position.y)),
                                       duration: TimeInterval(fallTime))
        item.run(moveAction)
        print("\(item.name ?? "nothing") added")
    }
    
    /*
     add scoring bins
     */
    func addBins(){
        compostBin = SKSpriteNode(imageNamed: "compost_bin")
        compostBin.position = CGPoint(x: compostBin.size.width / 2,
                                      y: compostBin.size.height)
        compostBin.zPosition = CGFloat(-1)
        addChild(compostBin)
    }
    
}

/*
 handle missed items
 */
extension GameScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact){
        //remove the item if it contacted the boundary
        if contact.bodyA.categoryBitMask == PhysicsCategory.item {
            contact.bodyA.node?.removeFromParent()
            itemsMissed += 1
            itemsMissedNode.text = "\(itemsMissed)"
            print("item removed")
        }
        
        if contact.bodyB.categoryBitMask == PhysicsCategory.item {
            contact.bodyB.node?.removeFromParent()
            itemsMissed += 1
            itemsMissedNode.text = "\(itemsMissed)"
            print("item removed")
        }
    }
}
