//
//  ItemAdderScene.swift
//  Recyclone
//
//  Created by Evan Huang on 12/25/20.
//

import SpriteKit
import GameplayKit
import MultipeerConnectivity
import GameKit

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

typealias CGTimeInterval = CGFloat
func +(left: TimeInterval, right: CGTimeInterval) -> CGTimeInterval {
    return CGTimeInterval(left) + CGTimeInterval(right)
}

func -(left: TimeInterval, right: CGTimeInterval) -> CGTimeInterval {
    return CGTimeInterval(left) - CGTimeInterval(right)
}

class ProgressiveProperty {
    var value: CGFloat
    var multiplier: CGFloat
    
    init(value: CGFloat, multiplier: CGFloat) {
        self.value = value
        self.multiplier = multiplier
    }
    
    func progressValue() {
        self.value *= self.multiplier
    }
    
    func regressValue() {
        self.value /= self.multiplier
    }
}


struct ItemMovement {
    var speed:         ProgressiveProperty      = ProgressiveProperty(value: -200, multiplier: 1.1)
    var spawnInterval: ProgressiveProperty = ProgressiveProperty(value: CGTimeInterval(1), multiplier:  0.85)
}

//MARK: Remove items from screen
extension ItemAdderScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact){
        //remove the item if it contacted the boundary
        let categoryBodyA = contact.bodyA.categoryBitMask
        let categoryBodyB = contact.bodyB.categoryBitMask
        if  categoryBodyA == PhysicsCategory.item && categoryBodyB == PhysicsCategory.boundary ||
                categoryBodyA == PhysicsCategory.boundary && categoryBodyB == PhysicsCategory.item {
            
            (categoryBodyA == PhysicsCategory.item ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
            itemDidContactBoundary()
            print("item removed")
        }
    }
    
    
}

class ItemAdderScene: SKScene {
    
    var trashItemTextures = Set<ItemTexture>()
    var itemMovement = ItemMovement()
    private var itemDropCountdown = CGTimeInterval(1)
    private var lastTimeInterval = CGTimeInterval(0)
    let NUM_OF_RECYCLE_IMG = 4
    let NUM_OF_COMPOST_IMG = 4
    let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    let BOUNDARY_OUTSET = CGFloat(100)
    var shouldSpawnItems = true
    let itemLayer = SKNode()
    
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = ColorScheme.currentColorClass.gameBackground
        loadItemTextures()
        
        //setup boundary removal physics for performance
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(
                                            x: -BOUNDARY_OUTSET,
                                            y: -BOUNDARY_OUTSET),
                                         to: CGPoint(
                                            x: SCREEN_WIDTH + BOUNDARY_OUTSET,
                                            y: -BOUNDARY_OUTSET))
        self.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        
        self.addChild(itemLayer)
        //prevent lazy initialization of audio player
        //TODO: figure out why this is working as expected -> everything inits properly but
        // audio doesnt play if there is a long period of time between an audio being played
        // maybe its being init but is not allocated/deallocated
        DispatchQueue.global().async {
            _ = LookAndFeel.audioScheme
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func itemDidContactBoundary() {
        
    }
    
    override func didMove(to view: SKView) {

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    deinit {
        print("game scene denitialized")
    }
    
    func cleanUp() {
        for child in self.children {
            print("clearing \(child)")
            child.removeAllActions()
            child.removeAllChildren()
            child.removeFromParent()
        }
        self.shouldSpawnItems = false
    }
    
    //MARK: Spawn items clock
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        let delta = currentTime - self.lastTimeInterval
        self.lastTimeInterval = CGTimeInterval(currentTime)
        self.itemDropCountdown -= delta
        
        if (self.itemDropCountdown <= 0 && shouldSpawnItems) {
            self.itemDropCountdown = self.itemMovement.spawnInterval.value
        }
    }
    
    func whenAddItemReady() {
        addItem()
    }
    
    /*
     random number generation
     */
    func random() -> CGFloat{
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    
    func random(min: CGFloat, max:CGFloat) -> CGFloat{
        return random() * (max-min) + min
    }
    
    /*
     add an item of trash onto the screen
     */
    func addItem(at position: CGPoint? = nil){
        let item = createRandomItem()
        if let position = position {
            item.position = position
        }
        itemLayer.addChild(item)
    }
    
    func createRandomItem() -> Item {
        //create a new item with a random texture
        var item = Item()
        if let randomItemTexture = trashItemTextures.randomElement() {
            item = Item(itemTexture: randomItemTexture)
            item.name = randomItemTexture.type.rawValue
            item.position = randomPointOutsideBounds(for: item.size)
            item.zPosition = CGFloat(ZPositions.item.rawValue)
            //set physics
            item.physicsBody?.velocity = CGVector(dx: 0,
                                                  dy: CGFloat(itemMovement.speed.value))
        }
        return item
    }
    
    func randomPointOutsideBounds(for size: CGSize) -> CGPoint {
        return randomPointOutsideBounds(for: size, outside: self.frame)
    }
    
    func randomPointOutsideBounds(for size: CGSize, outside bounds: CGRect) -> CGPoint {
        return CGPoint(x: random(min: size.width,
                                 max: bounds.width - size.width),
                       y: bounds.height + size.height)
    }
    
    func loadItemTextures() {
        //initialize trash item textures
        for i in 0..<NUM_OF_COMPOST_IMG{
            trashItemTextures.insert( ItemTexture(texture: SKTexture(imageNamed: "compost/compost\(i)"),
                                                  type: ItemType.compost))
        }
        for i in 0..<NUM_OF_RECYCLE_IMG{
            trashItemTextures.insert( ItemTexture(texture: SKTexture(imageNamed: "recycle/recycle\(i)"),
                                                  type: ItemType.recycle))
        }
    }
    
}
