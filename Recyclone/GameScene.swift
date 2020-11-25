//
//  GameScene.swift
//  Recyclone
//
//  Created by Evan Huang on 9/28/20.
//

import SpriteKit
import GameplayKit
import MultipeerConnectivity
import GameKit

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

enum ItemType: String {
    case recycle
    case trash
    case compost
    case none
}

enum ZPositions: Int {
    case background = -1
    case item = 0
    case foreground = 1
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

struct ItemTexture: Hashable{
    let texture: SKTexture
    let type: ItemType
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
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var trashItemTextures = Set<ItemTexture>()
    var itemSpeed = Float(200)
    let ITEM_SPEED_MULTI = Float(1.15);
    var itemDropCountdown = TimeInterval(1)
    var itemDropInterval = TimeInterval(1)
    let ITEM_INTERVAL_MULTI = Double(0.7)
    var lastTimeInterval = TimeInterval(0)
    var itemsMissed = 0 {
        didSet{
            itemsMissedNode.text = "\(itemsMissed)"
        }
    }
    var score = 0 {
        didSet {
            scoreNode.text = "\(score)"
        }
    }
    var scoreNode = SKLabelNode()
    var itemsMissedNode = SKLabelNode()
    let NUM_OF_RECYCLE_IMG = 1
    let NUM_OF_COMPOST_IMG = 1
    let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    var compostBin = SKSpriteNode()
    var recycleBin = SKSpriteNode()
    let BOUNDARY_OUTSET = CGFloat(100)
    let FONT_SIZE = 30
    let FONT_NAME = "HelveticaNeue"
    var itemTypeToBin = [ItemType : SKNode]()
    let hapticFeedback = UINotificationFeedbackGenerator()
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    var retryButton: Button?
    var mainMenuButton: Button?
    
    //map for associating individual touches with items
    private var touchToNode = [UITouch: SKNode]()
    
    /*
     when view is loaded
     */
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.white
        //initialize trash item textures
        for i in 0..<NUM_OF_COMPOST_IMG{
            trashItemTextures.insert( ItemTexture(texture: SKTexture(imageNamed: "compost/compost\(i)"),
                                                  type: ItemType.compost))
        }
        for i in 0..<NUM_OF_RECYCLE_IMG{
            trashItemTextures.insert( ItemTexture(texture: SKTexture(imageNamed: "recycle/recycle\(i)"),
                                                  type: ItemType.recycle))
        }
        print(trashItemTextures)
        print("width: \(SCREEN_WIDTH)")
        print("height: \(SCREEN_HEIGHT)")
        
        //setup boundary removal physics for performance and game over mechanism
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeFrom: CGPoint(
                                        x: -BOUNDARY_OUTSET,
                                        y: -BOUNDARY_OUTSET),
                                    to: CGPoint(
                                        x: SCREEN_WIDTH + BOUNDARY_OUTSET,
                                        y: -BOUNDARY_OUTSET))
        physicsBody?.categoryBitMask = PhysicsCategory.boundary
        
        //setup scoring
        scoreNode.position = CGPoint(x: SCREEN_WIDTH * 0.25,
                                     y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        scoreNode.text = "\(score)"
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
        
    }
    
    /*
     HANDLE TOUCH EVENTS
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        impactFeedback.prepare()
        for touch in touches{
            let location = touch.location(in: self)
            let touchedNodes = self.nodes(at: location)
            //reversed to select nodes that appear on top, first
            for node in touchedNodes.reversed(){
                if  node is Item &&
                        trashItemTextures.contains(((node as? Item)?.itemTexture)!){    //only allow user to drag trash items
                    node.isPaused = true
                    node.physicsBody?.isResting = true
                    self.touchToNode.updateValue(node, forKey: touch)
                    break
                } else if node.name == "Retry" || node.name == "Main Menu" &&
                            node.contains(location) {
                    impactFeedback.impactOccurred()
                    self.touchToNode.updateValue(node, forKey: touch)
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
        self.impactFeedback.prepare()
        
        for touch in touches{
            if let node = self.touchToNode[touch] as? Item {    //only get nodes that are a trash item
                
                let texture = node.itemTexture
                if  itemTypeToBin[texture.type] != nil &&
                        itemTypeToBin[texture.type]!.frame.contains(node.position) { //check if the item was placed in the right bin
                    
                    impactFeedback.impactOccurred()
                    score += 1
                    if (score%10 == 0){
                        itemDropInterval *= ITEM_INTERVAL_MULTI
                        itemSpeed *= ITEM_SPEED_MULTI
                    }
                    node.removeFromParent()
                } else {    //reset the movement of the node if it wasn't removed
                    node.physicsBody?.velocity = CGVector(dx: 0,
                                                          dy: CGFloat(-itemSpeed))
                }
                
                self.touchToNode[touch]?.isPaused = false
                self.touchToNode[touch]?.physicsBody?.isResting = false
                touchToNode.removeValue(forKey: touch)
            } else if let node = self.touchToNode[touch] {
                if node.contains(touch.location(in: self)) {
                    if node.name == "Retry" {
                        self.view?.isPaused = false
                        let retryScene = GameScene(size: self.size)
                        retryScene.scaleMode = self.scaleMode
                        let animation = SKTransition.fade(withDuration: 1.0)
                        self.scene?.view!.presentScene(retryScene, transition: animation)
                        
                    } else if node.name == "Main Menu" {
                        self.view?.isPaused = false
                        let mainMenuScene = MainMenuScene(size: self.size)
                        mainMenuScene.scaleMode = self.scaleMode
                        let animation = SKTransition.fade(withDuration: 1.0)
                        self.scene?.view!.presentScene(mainMenuScene, transition: animation)
                    }
                    self.impactFeedback.impactOccurred()
                }
            }
            
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
        let delta = currentTime - self.lastTimeInterval
        self.lastTimeInterval = currentTime
        self.itemDropCountdown -= delta
        
        if (self.itemDropCountdown <= 0) {
            addItem()
            self.itemDropCountdown = self.itemDropInterval
        }
    }
    
    /*
     run after any of the physics changes
     */
    override func didSimulatePhysics() {
        //only check endgame when physics changes -> contacts are made
        if(itemsMissed >= 10){
            retryButton = Button(label: "Retry", location: CGPoint(x: self.frame.midX, y: self.frame.midY + 50))
            retryButton?.shape.zPosition = CGFloat(ZPositions.foreground.rawValue)
            self.addChild(retryButton!.shape)
            
            mainMenuButton = Button(label: "Main Menu", location: CGPoint(x: self.frame.midX, y: self.frame.midY - 50))
            mainMenuButton?.shape.zPosition = CGFloat(ZPositions.foreground.rawValue)
            self.addChild(mainMenuButton!.shape)
            
            submitScore()
            self.view?.isPaused = true
        }
    }
    
    func submitScore() {
        if (GKLocalPlayer.local.isAuthenticated) {
            let gkScore = GKScore(leaderboardIdentifier: "com.highscore.Recyclone")
            gkScore.value = Int64(score)
            GKScore.report([gkScore]) { (error) in
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    print("High Score submitted to the leaderboard!")
                }
            }
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
            item.position = CGPoint(x: random(min: 0,
                                              max: SCREEN_WIDTH - item.size.width),
                                    y: SCREEN_HEIGHT + item.size.height)
            item.zPosition = CGFloat(ZPositions.item.rawValue)
            //set physics
            item.physicsBody?.velocity = CGVector(dx: 0,
                                                  dy: CGFloat(-itemSpeed))
            
            addChild(item)
            print("\(item.name ?? "nothing") added")
        }
    }
    
    /*
     add scoring bins
     */
    func addBins(){
        compostBin = SKSpriteNode(imageNamed: "compost_bin")
        compostBin.position = CGPoint(x: compostBin.size.width * 0.75,
                                      y: compostBin.size.height)
        compostBin.zPosition = CGFloat(ZPositions.background.rawValue)
        itemTypeToBin.updateValue(compostBin, forKey: ItemType.compost)
        addChild(compostBin)
        
        recycleBin = SKSpriteNode(imageNamed: "recycle_bin")
        recycleBin.position = CGPoint(x: SCREEN_WIDTH - recycleBin.size.width * 0.75,
                                      y: recycleBin.size.height)
        recycleBin.zPosition = CGFloat(ZPositions.background.rawValue)
        itemTypeToBin.updateValue(recycleBin, forKey: ItemType.recycle)
        addChild(recycleBin)
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
            self.hapticFeedback.notificationOccurred(.warning)
            itemsMissed += 1
            print("item removed")
        }
        
        if contact.bodyB.categoryBitMask == PhysicsCategory.item {
            contact.bodyB.node?.removeFromParent()
            self.hapticFeedback.notificationOccurred(.warning)
            itemsMissed += 1
            print("item removed")
        }
    }
}
