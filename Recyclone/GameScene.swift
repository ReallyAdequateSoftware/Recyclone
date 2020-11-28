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

enum ZPositions: Int {
    case background = -1
    case item = 0
    case foreground = 1
}

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
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


class GameScene: SKScene {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var trashItemTextures = Set<ItemTexture>()
    var itemSpeed = Float(200)
    let ITEM_SPEED_MULTI = Float(1.1);
    var itemDropCountdown = TimeInterval(1)
    var itemDropInterval = TimeInterval(1)
    let ITEM_INTERVAL_MULTI = Double(0.85)
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
    let NUM_OF_RECYCLE_IMG = 4
    let NUM_OF_COMPOST_IMG = 4
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
    var buttonNameToFunction = [(String, () -> Void)]()
    var isPlaying = true
    
    let scoringLayer = SKNode()
    let itemLayer = SKNode()
    let buttonLayer = SKNode()
    
    //map for associating individual touches with items
    private var touchToNode = [UITouch: SKNode]()
    
    /*
     when view is loaded
     */
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.white
        loadItemTextures()
        
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
        
        //initialize "game over" buttons
        
        buttonNameToFunction = [("Retry", retryGame),
                                ("Main Menu", goToMainMenu),
        ]
        
        for (index, (name, function)) in buttonNameToFunction.enumerated() {
            let button = Button(label: name,
                                location: CGPoint(x: self.frame.midX,
                                                  y: self.frame.midY + 50 - CGFloat((index * 100))),
                                function: function)
            button.zPosition = CGFloat(ZPositions.foreground.rawValue)
            buttonLayer.addChild(button)
        }
        
        initScoring()
        
        self.addChild(scoringLayer)
        self.addChild(itemLayer)
        
    }
    
    // TODO: maybe these should be combined into single function that decides next scene based off the buttons name
    func retryGame() -> Void {
        let nextScene = GameScene(size: self.size)
        nextScene.scaleMode = self.scaleMode
        let animation = SKTransition.crossFade(withDuration: TimeInterval(1.0))
        cleanUp()
        self.view?.presentScene(nextScene, transition: animation)
    }
    
    func goToMainMenu() -> Void {
        let nextScene = MainMenuScene(size: self.size)
        nextScene.scaleMode = self.scaleMode
        let animation = SKTransition.crossFade(withDuration: TimeInterval(1.0))
        cleanUp()
        self.view?.presentScene(nextScene, transition: animation)
    }
    
    /*
     HANDLE TOUCH EVENTS
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        impactFeedback.prepare()
        for touch in touches{
            let location = touch.location(in: self)
            let touchedNodes = self.nodes(at: location)
            for node in touchedNodes {
                if self.touchToNode[touch] == nil { //only allow for a touch to select a single node
                    if node.parent == itemLayer {
                        node.isPaused = true
                        node.physicsBody?.isResting = true
                        self.touchToNode.updateValue(node, forKey: touch)
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            if let itemNode = touchToNode[touch],
               itemNode is Item &&
                self.isPlaying { //only update touch map when the item touched is an item and we're still playing
                itemNode.isPaused = true
                itemNode.position = touch.location(in: self)
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.impactFeedback.prepare()
        for touch in touches {
            
            let touchedNodes = self.nodes(at: touch.location(in: self))
            for touchedNode in touchedNodes.reversed() {
                if let previouslyTouched = self.touchToNode[touch],
                   previouslyTouched == touchedNode { //only process touches that started and ended on the same node
                    if previouslyTouched.parent == itemLayer { //handle trash items
                        let texture = (previouslyTouched as! Item).itemTexture
                        let binNode = itemTypeToBin[texture.type]!

                        if  binNode.intersects(previouslyTouched) { //check if the item was placed in the right bin
                            impactFeedback.impactOccurred()
                            score += 1
                            evaluateDifficulty()
                            previouslyTouched.removeFromParent()
                        } else {    //reset the movement of the node if it wasn't removed
                            previouslyTouched.physicsBody?.velocity = CGVector(dx: 0,
                                                                               dy: CGFloat(-itemSpeed))
                        }
                        self.touchToNode[touch]?.isPaused = false
                        self.touchToNode[touch]?.physicsBody?.isResting = false
                        touchToNode.removeValue(forKey: touch)
                        
                    }
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
    
    deinit {
        print("denitialized")
    }
    
    func cleanUp() {
        for child in self.children {
            print("clearing \(child)")
            child.removeAllActions()
            child.removeAllChildren()
            child.removeFromParent()
        }
        self.isPlaying = false
        self.retryButton = nil
        self.mainMenuButton = nil
        self.itemsMissed = 0
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        let delta = currentTime - self.lastTimeInterval
        self.lastTimeInterval = currentTime
        self.itemDropCountdown -= delta
        
        if (self.itemDropCountdown <= 0 && isPlaying) {
            addItem()
            self.itemDropCountdown = self.itemDropInterval
        }
    }
    
    /*
     run after any of the physics changes
     */
    override func didSimulatePhysics() {
        //only check endgame when physics changes -> contacts are made
        if(self.itemsMissed >= 10 && self.isPlaying){
            pauseGame()
            submitScore()
        }
    }
    
    func pauseGame() {
        self.isPlaying = false
        physicsWorld.speed = 0
        for child in itemLayer.children {
            child.isPaused = true
            child.removeAllActions()
        }
        if buttonLayer.parent == nil {
            self.addChild(buttonLayer)
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

    
    func evaluateDifficulty() {
        if score % 10 == 0 {
            itemDropInterval *= ITEM_INTERVAL_MULTI
            itemSpeed *= ITEM_SPEED_MULTI
        }
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
            
            itemLayer.addChild(item)
            print("\(item.name ?? "nothing") added")
        }
    }
    
    /*
     create everything we need to score the game
     */
    func initScoring() {
        
        //setup scoring
        scoreNode.position = CGPoint(x: SCREEN_WIDTH * 0.25,
                                     y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        scoreNode.zPosition = CGFloat(ZPositions.foreground.rawValue)
        scoreNode.text = "\(score)"
        scoreNode.fontColor = UIColor.green
        scoreNode.fontSize = CGFloat(FONT_SIZE)
        scoreNode.fontName = FONT_NAME
        scoringLayer.addChild(scoreNode)
        
        itemsMissedNode.text = "\(itemsMissed)"
        itemsMissedNode.position = CGPoint(x: SCREEN_WIDTH * 0.75,
                                           y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        itemsMissedNode.zPosition = CGFloat(ZPositions.foreground.rawValue)
        itemsMissedNode.fontColor = UIColor.red
        itemsMissedNode.fontSize = CGFloat(FONT_SIZE)
        itemsMissedNode.fontName = FONT_NAME
        scoringLayer.addChild(itemsMissedNode)
        
        //setup scoring bins
        compostBin = SKSpriteNode(imageNamed: "compost_bin")
        compostBin.position = CGPoint(x: compostBin.size.width * 0.75,
                                      y: compostBin.size.height)
        compostBin.zPosition = CGFloat(ZPositions.background.rawValue)
        itemTypeToBin.updateValue(compostBin, forKey: ItemType.compost)
        scoringLayer.addChild(compostBin)
        
        recycleBin = SKSpriteNode(imageNamed: "recycle_bin")
        recycleBin.position = CGPoint(x: SCREEN_WIDTH - recycleBin.size.width * 0.75,
                                      y: recycleBin.size.height)
        recycleBin.zPosition = CGFloat(ZPositions.background.rawValue)
        itemTypeToBin.updateValue(recycleBin, forKey: ItemType.recycle)
        scoringLayer.addChild(recycleBin)
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
