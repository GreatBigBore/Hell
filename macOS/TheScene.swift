import SpriteKit
import GameplayKit

class TheScene: SKScene {

    var entities = [GKEntity]()
    var graphs = [String: GKGraph]()

    private var lastUpdateTime: TimeInterval = 0
    private var tickCount = 0

    override func didMove(to view: SKView) {
        self.lastUpdateTime = 0

        physicsWorld.gravity = CGVector.zero

//        let background = (childNode(withName: "net_portal") as? SKSpriteNode)!
//        let background = (childNode(withName: "arkons_portal") as? SKSpriteNode)!
//        let spriteFactory = SpriteFactory(scene: self)
//
//        Manna.grazeTest(background: background, scene: self)
//        Arkon.inject(spriteFactory, background)
//        Arkon.grazeTest()

//        NetDisplayGrid.selfTest(background: background)
//        NetGraphics.selfTest(background: background, scene: self)
//        SpriteFactory.selfTest(scene: self)

//        NetDisplay(scene: self, background: background).display(net: [12, 9, 9, 5])

//        Metabolism.selfTest()
    }

    func touchDown(atPoint pos: CGPoint) {
    }

    func touchMoved(toPoint pos: CGPoint) {
    }

    func touchUp(atPoint pos: CGPoint) {
    }

    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }

    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }

    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }

    override func update(_ currentTime: TimeInterval) {
        defer { tickCount += 1 }
        if tickCount < 10 { return }

        // Called before each frame is rendered

        // Initialize _lastUpdateTime if it has not already been
        if self.lastUpdateTime == 0 {
            self.lastUpdateTime = currentTime

            let background = (childNode(withName: "arkons_portal") as? SKSpriteNode)!
            Maneuvers.selfTest(background: background, scene: self)
//            Manna.selfTest(background: background, scene: self)

            return
        }

        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime

        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }

        self.lastUpdateTime = currentTime
    }
}
