import Foundation
import SpriteKit

extension CGFloat { static let tau = 2 * CGFloat.pi }

class Karamba: SKSpriteNode {
    var arkon: Arkon!
    var contactedBodies: [SKPhysicsBody]?
    let geneticParentFishNumber: Int?
    let geneticParentGenome: [GeneProtocol]?
    var isAlive = false
    var metabolism = Metabolism()
    var mostRecentAction = ActionPrimitive.goWait(0)
    var previousPosition = CGPoint.zero
    var readyForPhysics = false
    var isReadyForTick = false
    var sensedBodies: [SKPhysicsBody]?
    var sensoryInputs = [Double]()

    init(_ geneticParentFishNumber: Int?, _ geneticParentGenome: [GeneProtocol]?) {
        self.geneticParentGenome = geneticParentGenome
        self.geneticParentFishNumber = geneticParentFishNumber

        super.init(
            texture: ArkonCentralLight.topTexture,
            color: .yellow,
            size: ArkonCentralLight.topTexture!.size()
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Convenience & readability

extension Karamba {
    var nose: KNoseNode { return hardBind(childNode(withName: "nose") as? KNoseNode) }
    var pBody: SKPhysicsBody { return physicsBody! }
    var portal: SKSpriteNode { return PortalServer.shared.arkonsPortal }
    var scab: Arkon { return hardBind(arkon) }
//    var sensor: SKPhysicsBody { return hardBind(nose.physicsBody) }

    var isInBounds: Bool {
        let relativeToPortal = portal.convert(frame.origin, to: portal.parent!)

        let w = size.width * portal.xScale
        let h = size.height * portal.yScale
        let scaledSize = CGSize(width: w, height: h)
        let arkonRectangle = CGRect(origin: relativeToPortal, size: scaledSize)

        // Remember: get the scene frame rather than the portal frame because
        // that's how big the portal's children think the portal is. We can't
        // use the portal's frame, because it is doing its own thing due to scaling.
        return portal.frame.contains(arkonRectangle)
    }
}

// MARK: Construction & setup

extension Karamba {
    private static func darkOps(
        _ geneticParentFishNumber: Int?, _ geneticParentGenome: [GeneProtocol]?
    ) {
        let nose = KNoseNode(
            texture: ArkonCentralLight.topTexture,
            color: .green,
            size: ArkonCentralLight.topTexture!.size()
        )

        nose.name = "nose_awaiting_fish_number"
        nose.setScale(0.75)
        nose.colorBlendFactor = 1.0
        nose.zPosition = ArkonCentralLight.vArkonZPosition + 1

        let arkon = Karamba(geneticParentFishNumber, geneticParentGenome)
        arkon.colorBlendFactor = 1.0
        arkon.zPosition = ArkonCentralLight.vArkonZPosition

        let (pBody, nosePBody) = makePhysicsBodies(arkonRadius: arkon.size.radius)
        arkon.metabolism.pBody = pBody

        let parentGenome = geneticParentGenome ?? ArkonFactory.getAboriginalGenome()

        guard let scab = ArkonFactory.shared.makeArkon(
            parentFishNumber: geneticParentFishNumber, parentGenome: parentGenome
        ) else { return }    // Arkon died due to non-viable genome

        arkon.arkon = scab
        arkon.name = "arkon_\(scab.fishNumber)"
        nose.name = "nose_\(scab.fishNumber)"
        arkon.setScale(ArkonFactory.scale)

        let portal = PortalServer.shared.arkonsPortal
        let xRange = -portal.frame.size.width..<portal.frame.size.width
        let yRange = -portal.frame.size.height..<portal.frame.size.height
        arkon.position = CGPoint.random(xRange: xRange, yRange: yRange)
        arkon.zRotation = CGFloat.random(in: 0..<CGFloat.tau)

        World.shared.populationChanged = true

        // The physics engine becomes unhappy if we add the arkon to the portal
        // in the wrong phase of the display cycle, which happens because we're
        // running all this setup on a work queue rather than in the main display
        // update. So instead of adding in this context, we hand off an action to
        // the portal and let him add us when it's safe.
        let action = SKAction.run {
            portal.addChild(arkon)
            arkon.addChild(nose)

            // Surprisingly, the physics engine also becomes unhappy if we add
            // the physics bodies before we add their owning nodes to the scene.
            arkon.physicsBody = pBody
            nose.physicsBody = nosePBody

            nosePBody.pinned = true // It wouldn't do to leave our senses behind
        }

        portal.run(action, completion: { arkon.isReadyForTick = true; scab.status.isAlive = true })
    }

    static func makeDrone(geneticParentFishNumber f: Int?, geneticParentGenome g: [GeneProtocol]?) {
        ArkonFactory.karambaSerializerQueue.async { darkOps(f, g) }
    }

    static func makePhysicsBodies(arkonRadius: CGFloat) -> (SKPhysicsBody, SKPhysicsBody) {
        let sensesPBody = SKPhysicsBody(circleOfRadius: arkonRadius * 1.5)
        let edible =
            ArkonCentralLight.PhysicsBitmask.mannaBody.rawValue |
            ArkonCentralLight.PhysicsBitmask.arkonBody.rawValue

        sensesPBody.mass = 0.1
        sensesPBody.allowsRotation = false
        sensesPBody.collisionBitMask = 0
        sensesPBody.contactTestBitMask = edible
        sensesPBody.categoryBitMask = ArkonCentralLight.PhysicsBitmask.arkonSenses.rawValue

        let pBody = SKPhysicsBody(circleOfRadius: arkonRadius / 14)

        pBody.mass = 1
        pBody.collisionBitMask = ArkonCentralLight.PhysicsBitmask.arkonBody.rawValue
        pBody.contactTestBitMask = edible
        pBody.categoryBitMask = ArkonCentralLight.PhysicsBitmask.arkonBody.rawValue
        pBody.fieldBitMask = 0

        return (pBody, sensesPBody)
    }
}

extension Karamba {
    func apoptosize() {
        scab.status.isAlive = false
        run(SKAction.removeFromParent())
    }

    func apparate() { PortalServer.shared.arkonsPortal.addChild(self) }

    enum CombatStatus { case losing(Karamba), surviving, winning(Karamba)  }
    enum HerbivoreStatus { case goingHungry, grazing }

    func calorieTransfer() {
        let combatStatus = combat()

        var opponent: Karamba!
        switch combatStatus {
        case let .losing(k):  opponent = k; return
        case let .winning(k): opponent = k
        case .surviving:      break
        }

        if let victim = opponent { eatArkon(victim) }

        let herbivoreStatus = graze()
        if herbivoreStatus == .grazing { eatManna() }
    }

    func combat() -> CombatStatus {
        let contactedArkons = getContactedArkons()

        guard let ca = contactedArkons, ca.count == 1,
              let opponent = ca.first?.node as? Karamba,
              let oca = opponent.getContactedArkons(), oca.count <= 1
            else { return .surviving }

        return (opponent.pBody.mass * opponent.metabolism.health - opponent.metabolism.hunger) >
               (self.pBody.mass     * self.metabolism.health     - self.metabolism.hunger)     ?
                .losing(opponent) : .winning(opponent)
    }

    static func createDrones(_ cKarambas: Int) {
        (0..<cKarambas).forEach { _ in
            Karamba.makeDrone(geneticParentFishNumber: nil, geneticParentGenome: nil)
        }
    }

    func graze() -> HerbivoreStatus {
        let contactedManna = getContactedManna()

        guard let cm = contactedManna, cm.isEmpty == false else { return .goingHungry }
        return .grazing
    }

    func lastMinuteBusiness() {
        let a: Arkon = self.arkon
        if a.scheduledActions.isEmpty { return }

        defer { a.scheduledActions.removeAll() }
        run(SKAction.sequence(a.scheduledActions))
    }

    func response(motorNeuronOutputs: [Double]) {
        let m = motorNeuronOutputs
        let actionPrimitive = selectActionPrimitive(arkon: self, motorOutputs: m)
        run(actionPrimitive)
    }

    func tick() {
        // Because the physics engine gets cranky if we try to add physics
        // bodies to our nodes before we add the nodes to the scene, we have
        // to allow for the scene to start ticking us before we're fully ready
        // (that is, before we've added the physics bodies). So don't do anything
        // until isAlive is set.
        guard scab.status.isAlive else { return }
        readyForPhysics = true
        isReadyForTick = false

        guard isInBounds && metabolism.health > 0.1 else {
            if metabolism.oxygenLevel < 0.01 {
                Karamba.makeDrone(geneticParentFishNumber: nil, geneticParentGenome: nil)
                metabolism.giveBirth()
            }

            apoptosize()
            return
        }

        if let cb = contactedBodies, cb.isEmpty == false { calorieTransfer() }
        if metabolism.health >= 0.9 {
            let a = hardBind(arkon)
            Karamba.makeDrone(geneticParentFishNumber: a.fishNumber, geneticParentGenome: a.genome)
            metabolism.giveBirth()
        }

        // Coincidentally, in Arkonia, we measure distance and volume using
        // the same units.
        metabolism.inhale(position.distance(to: previousPosition))
        metabolism.tick()

        previousPosition = position

        let stimulusAction = SKAction.run { self.stimulus() }
        let netSignalAction = SKAction.run(netSignal, queue: ArkonFactory.karambaStimulusQueue)
        let responseAction = SKAction.run { self.response() }
        let sequence = SKAction.sequence([stimulusAction, netSignalAction, responseAction])
        run(sequence) { self.isReadyForTick = true }
    }
}

extension Karamba: ManeuverProtocol {
    override var scene: SKScene { return hardBind(Display.shared.scene) }
}
