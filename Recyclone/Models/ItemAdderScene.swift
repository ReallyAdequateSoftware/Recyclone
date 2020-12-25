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

class ProgressiveProperty<Multipliable : Numeric> {
    var value: Multipliable
    var multiplier: CGFloat
    
    init(value: Multipliable, multiplier: CGFloat) {
        self.value = value
        self.multiplier = multiplier
    }
    
    func progressValue() {
        self.value *= multiplier as! Multipliable
    }
}

struct ItemMovement {
    var speed:         ProgressiveProperty<CGFloat>      = ProgressiveProperty(value: -200, multiplier: 1.1)
    var spawnInterval: ProgressiveProperty<TimeInterval> = ProgressiveProperty(value: TimeInterval(1), multiplier:  0.85)
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
            //move this to game scene only
            //LookAndFeel.gameplayFeedback.notificationOccurred(.warning)
            //LookAndFeel.audioScheme.missed.play()
            //itemsMissed += 1
            print("item removed")
        }
    }
}

class ItemAdderScene: SKScene {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var trashItemTextures = Set<ItemTexture>()
    var itemMovement = ItemMovement()
    var itemDropCountdown = TimeInterval(1)
    var lastTimeInterval = TimeInterval(0)
    let NUM_OF_RECYCLE_IMG = 4
    let NUM_OF_COMPOST_IMG = 4
    let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    let BOUNDARY_OUTSET = CGFloat(100)
    var shouldSpawnItems = true
    let itemLayer = SKNode()
    
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = LookAndFeel.currentColorScheme.gameBackground
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {

    }
    
    
    //MARK: Touch event handling
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
        self.lastTimeInterval = currentTime
        self.itemDropCountdown -= delta
        
        if (self.itemDropCountdown <= 0 && shouldSpawnItems) {
            addItem()
            self.itemDropCountdown = self.itemMovement.spawnInterval.value
        }
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
    func addItem(){
        //create a new item with a random texture
        if let randomItemTexture = trashItemTextures.randomElement(){
            let item = Item(itemTexture: randomItemTexture)
            item.name = randomItemTexture.type.rawValue
            item.position = CGPoint(x: random(min: item.size.width,
                                              max: SCREEN_WIDTH - item.size.width),
                                    y: SCREEN_HEIGHT + item.size.height)
            item.zPosition = CGFloat(ZPositions.item.rawValue)
            //set physics
            item.physicsBody?.velocity = CGVector(dx: 0,
                                                  dy: CGFloat(itemMovement.speed.value))
            
            //increase touchable area for smaller items
            if item.size.height * item.size.width < 7000 {
                let largestDimension = max(item.size.height, item.size.width)
                let touchArea = SKShapeNode(circleOfRadius: largestDimension / 2)
                touchArea.alpha = 0.0
                item.addChild(touchArea)
            }
            
            itemLayer.addChild(item)
            print("\(item.name ?? "nothing") added")
        }
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
