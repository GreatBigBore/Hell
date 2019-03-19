import Foundation
import SpriteKit

enum DisplayCycle: Int {
    case limbo
    case updateStarted
    case actions, actionsComplete
    case physics, physicsComplete
    case constraints, constraintsComplete
    case updateComplete

    func isIn(_ state: DisplayCycle) -> Bool { return self.rawValue == state.rawValue }
    func isPast(_ milestone: DisplayCycle) -> Bool { return self.rawValue >= milestone.rawValue }
}

class Display: NSObject, SKSceneDelegate {
    static var shared: Display!
    static var displayCycle: DisplayCycle = .limbo

    var appIsReadyToRun = false
    var currentTime: TimeInterval = 0
    private var frameCount = 0
    private var kNet: KNet?
    private var kNets = [SKSpriteNode: KNet]()
    private var portalServer: PortalServer!
    private var quadrants = [Int: SKSpriteNode]()
    public weak var scene: SKScene?
    public var tickCount = 0
    var timeZero: TimeInterval = 0

    var gameAge: TimeInterval { return currentTime - timeZero }

    init(_ scene: SKScene) {
        self.scene = scene
        self.portalServer = PortalServer(scene: scene)

        super.init()

        self.portalServer.clockPortal.setUpdater { [weak self] in return self?.gameAge ?? 0 }
    }

    // https://developer.apple.com/documentation/spritekit/skscene/responding_to_frame-cycle_events

    func didFinishUpdate(for scene: SKScene) {
        Display.displayCycle = .updateComplete
        // Do last-chance stuff
        Display.displayCycle = .limbo
    }

    func didEvaluateActions(for scene: SKScene) {
        Display.displayCycle = .actionsComplete
        Display.displayCycle = .physics
    }

    func didSimulatePhysics(for scene: SKScene) {
        Display.displayCycle = .physicsComplete
        Display.displayCycle = .constraints
    }

    func didApplyConstraints(for scene: SKScene) {
        Display.displayCycle = .constraintsComplete
        Display.displayCycle = .updateComplete
    }

    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        Display.displayCycle = .updateStarted
        primaryUpdate(currentTime, for: scene)
        Display.displayCycle = .actions
    }

    /**
     Schedule the kNet to be displayed on the next update.

     - Parameters:
         - kNet: The net to be displayed
         - portal: The portal on which to display it

     Does not display the net immediately, as we call it in a
     non-main thread context. We schedule it to be displayed on
     the next scene update

     */
    func display(_ kNet: KNet, portal: SKSpriteNode) {
        portal.removeAllChildren()
        self.kNet = kNet
    }

    var firstPass = true
    var babyFirstSteps = true

    func primaryUpdate(_ currentTime: TimeInterval, for scene: SKScene) {
        defer { self.currentTime = currentTime }
        if self.currentTime == 0 { self.timeZero = currentTime; return }

        // Mostly so the clock will stop running
        if ArkonFactory.shared!.cLiveArkons <= 0 &&
            !ArkonFactory.shared.pendingArkons.isEmpty && !babyFirstSteps { return }

        if firstPass {
            ArkonFactory.shared.spawnStarterPopulation(cArkons: 100)
            firstPass = false
            return
        }

        if let protoArkon = ArkonFactory.shared.pendingArkons.popFront() { protoArkon.launch() }

        if scene.physicsWorld.contactDelegate == nil && ArkonFactory.shared.pendingArkons.isEmpty {
            scene.physicsWorld.contactDelegate = World.shared.physics
            scene.physicsWorld.speed = 1.0
        }

        tickCount += 1

        if let kNet = self.kNet {
            DNet(kNet).display(via: PortalServer.shared.netPortal)
            self.kNet = nil
        }
    }
}
