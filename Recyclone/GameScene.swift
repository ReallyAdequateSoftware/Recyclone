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

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

//MARK: Remove items from screen
extension GameScene: SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact){
        //remove the item if it contacted the boundary
        let categoryBodyA = contact.bodyA.categoryBitMask
        let categoryBodyB = contact.bodyB.categoryBitMask
        if  categoryBodyA == PhysicsCategory.item && categoryBodyB == PhysicsCategory.boundary ||
                categoryBodyA == PhysicsCategory.boundary && categoryBodyB == PhysicsCategory.item {
            
            (categoryBodyA == PhysicsCategory.item ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
            LookAndFeel.gameplayFeedback.notificationOccurred(.warning)
            LookAndFeel.audioScheme.missed.play()
            itemsMissed += 1
            print("item removed")
        }
    }
}


class GameScene: SKScene {
    
    var gcWranglerDelegate: GCWrangler?
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
    var itemTypeToBin = [ItemType : SKNode]()
    var retryButton: Button?
    var mainMenuButton: Button?
    var gamePlayIsPaused = false
    var gameOver = false
    
    let scoringLayer = SKNode()
    let itemLayer = SKNode()
    
    //map for associating individual touches with items
    private var touchToNode = [UITouch: SKNode]()
    
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = LookAndFeel.currentColorScheme.gameBackground
        loadItemTextures()
        
        //setup boundary removal physics for performance and game over mechanism
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(
                                            x: -BOUNDARY_OUTSET,
                                            y: -BOUNDARY_OUTSET),
                                         to: CGPoint(
                                            x: SCREEN_WIDTH + BOUNDARY_OUTSET,
                                            y: -BOUNDARY_OUTSET))
        self.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        
        initScoring()
        initPauseButton()
        
        self.addChild(scoringLayer)
        self.addChild(itemLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     when view is loaded
     */
    override func didMove(to view: SKView) {
        if gamePlayIsPaused {
            unpauseGame()
        }
    }
    
    
    //MARK: Touch event handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        LookAndFeel.gameplayFeedback.prepare()
        for touch in touches{
            let location = touch.location(in: self)
            let touchedNodes = self.nodes(at: location)
            for node in touchedNodes {
                if self.touchToNode[touch] == nil { //only allow for a touch to select a single node
                    if node.inParentHierarchy(itemLayer){
                        node.isPaused = true
                        node.physicsBody?.isResting = true
                        //the map should only store Item nodes, not the extra node added for a larger touch area
                        self.touchToNode.updateValue(((node is Item ? node: node.parent)!), forKey: touch)
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            if let itemNode = touchToNode[touch],
               !gamePlayIsPaused { //only update touch map when the item touched is an item and we're still playing
                itemNode.isPaused = true
                itemNode.position = touch.location(in: self)
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let touchedNodes = self.nodes(at: touch.location(in: self))
            for touchedNode in touchedNodes.reversed() {
                if let previouslyTouched = self.touchToNode[touch],
                   previouslyTouched == touchedNode { //only process touches that started and ended on the same node
                    if previouslyTouched.parent == itemLayer { //handle trash items
                        let texture = (previouslyTouched as! Item).itemTexture
                        let binNode = itemTypeToBin[texture.type]!
                        
                        if  binNode.intersects(previouslyTouched) { //check if the item was placed in the right bin
                            LookAndFeel.buttonFeedback.impactOccurred()
                            LookAndFeel.audioScheme.success.play()
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
        print("game scene denitialized")
    }
    
    func cleanUp() {
        for child in self.children {
            print("clearing \(child)")
            child.removeAllActions()
            child.removeAllChildren()
            child.removeFromParent()
        }
        self.gamePlayIsPaused = true
        self.gameOver = true
        self.retryButton = nil
        self.mainMenuButton = nil
        self.itemsMissed = 0
    }
    
    //MARK: Spawn items clock
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        let delta = currentTime - self.lastTimeInterval
        self.lastTimeInterval = currentTime
        self.itemDropCountdown -= delta
        
        if (self.itemDropCountdown <= 0 && !gamePlayIsPaused) {
            addItem()
            self.itemDropCountdown = self.itemDropInterval
        }
    }
    
    //MARK: Check endgame conditions
    override func didSimulatePhysics() {
        //only check endgame when physics changes -> contacts are made
        if(self.itemsMissed >= 10 && !gamePlayIsPaused){
            gameOver = true
            pauseGame()
            submitScore()
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
    
    //MARK: Difficulty calculation
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
            item.position = CGPoint(x: random(min: item.size.width,
                                              max: SCREEN_WIDTH - item.size.width),
                                    y: SCREEN_HEIGHT + item.size.height)
            item.zPosition = CGFloat(ZPositions.item.rawValue)
            //set physics
            item.physicsBody?.velocity = CGVector(dx: 0,
                                                  dy: CGFloat(-itemSpeed))
            
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
    
    /*
     create everything we need to score the game
     */
    func initScoring() {
        
        //setup scoring
        scoreNode.position = CGPoint(x: SCREEN_WIDTH * 0.25,
                                     y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        scoreNode.zPosition = CGFloat(ZPositions.foreground.rawValue)
        scoreNode.text = "\(score)"
        scoreNode.fontColor = LookAndFeel.currentColorScheme.scoredItemsText
        scoreNode.fontSize = LookAndFeel.fontScheme.scoreFontSize
        scoreNode.fontName = LookAndFeel.fontScheme.scoreFontName
        scoringLayer.addChild(scoreNode)
        
        itemsMissedNode.text = "\(itemsMissed)"
        itemsMissedNode.position = CGPoint(x: SCREEN_WIDTH * 0.75,
                                           y: SCREEN_HEIGHT - BOUNDARY_OUTSET)
        itemsMissedNode.zPosition = CGFloat(ZPositions.foreground.rawValue)
        itemsMissedNode.fontColor = LookAndFeel.currentColorScheme.missedItemsText
        itemsMissedNode.fontSize = LookAndFeel.fontScheme.scoreFontSize
        itemsMissedNode.fontName = LookAndFeel.fontScheme.scoreFontName
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
    
    //MARK: Pause
    func initPauseButton() {
        //system images are vectors and spritekit cannot handle them, so we have to convert
        var pauseUnpress = UIImage(systemName: "pause.fill")!
            .withTintColor(LookAndFeel.currentColorScheme.unpressedButton, renderingMode: .alwaysOriginal)
        pauseUnpress = UIImage(data: pauseUnpress.pngData()!)!
        
        var pausePress = UIImage(systemName: "pause.fill")!
            .withTintColor(LookAndFeel.currentColorScheme.pressedButton, renderingMode: .alwaysOriginal)
        pausePress = UIImage(data: pausePress.pngData()!)!
        
        //view.safeAreaInsets does not work for some reason
        let safeAreaInsets = UIApplication.shared.delegate?.window??.safeAreaInsets
        let pauseButton = Button(label: "pause", location: CGPoint(x: self.frame.midX,
                                                                   y: self.frame.maxY - safeAreaInsets!.top - pauseUnpress.size.height / 2),
                                 unpressedImage: pauseUnpress,
                                 pressedImage: pausePress,
                                 function: pauseGame)
        pauseButton.zPosition = ZPositions.foreground.rawValue
        self.addChild(pauseButton)
    }
    
    func unpauseGame() {
        gamePlayIsPaused = false
        physicsWorld.speed = 1.0
        for child in itemLayer.children {
            child.isPaused = false
        }
    }
    
    func pauseGame() {
        gamePlayIsPaused = true
        physicsWorld.speed = 0
        for child in itemLayer.children {
            child.isPaused = true
            //child.removeAllActions()
        }
        
        if let screenshot = getScreenshot() {
            DispatchQueue.global(qos: .userInteractive).async {
                let blurredGameSceneImage = self.blurImage(with: screenshot, blurAmount: 40.0)
                DispatchQueue.main.async {
                    let nextScene = InGameMenuScene(size: self.size,
                                                    background: blurredGameSceneImage,
                                                    gcWranglerDelegate: self.gcWranglerDelegate!,
                                                    previousScene: self,
                                                    gameOver: self.gameOver)
                    nextScene.scaleMode = self.scaleMode
                    //crossfade can look like its fading to black first because the opacity starts at 0 and shows the background
                    //make sure to set next scenes background color to the same as this ones to fix this
                    nextScene.backgroundColor = self.backgroundColor
                    let animation = SKTransition.crossFade(withDuration: TimeInterval(0.4))
                    //cleanUp()
                    self.view?.presentScene(nextScene, transition: animation)
                }
            }
        }
        
    }
    
    func getScreenshot() -> UIImage? {
        //self.scene!.view?.bounds
        let bounds = self.view?.bounds
        UIGraphicsBeginImageContextWithOptions(bounds!.size, true, UIScreen.main.scale)
        self.view?.drawHierarchy(in: bounds!, afterScreenUpdates: true)
        guard let screenshot = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return screenshot;
    }
    
    func blurImage(with sourceImage: UIImage, blurAmount: CGFloat) -> UIImage {
        //  Create our blurred image
        let context = CIContext(options: nil)
        let inputImage = CIImage(cgImage: sourceImage.cgImage!)
        //  Setting up Gaussian Blur
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(blurAmount, forKey: "inputRadius")
        let result = filter?.value(forKey: kCIOutputImageKey) as? CIImage
        
        /*  CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches
         *  up exactly to the bounds of our original image */
        
        let cgImage = context.createCGImage(result ?? CIImage(), from: inputImage.extent)
        return UIImage(cgImage: cgImage!, scale: sourceImage.scale * 0.98, orientation: sourceImage.imageOrientation)
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
