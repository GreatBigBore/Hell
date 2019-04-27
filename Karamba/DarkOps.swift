import Foundation
import SpriteKit

enum KarambaDarkOps {
    static func darkOps(
        _ geneticParentFishNumber: Int?, _ geneticParentGenome: [GeneProtocol]?
    ) {
        let nose = setupNose()

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

        let scene = hardBind(Display.shared.scene)
        let portal = hardBind(scene.childNode(withName: "arkons_portal") as? SKSpriteNode)
        let w: CGFloat = portal.frame.size.width / 2.0
        let h: CGFloat = portal.frame.size.height / 2.0

        let xRange = -w..<w
        let yRange = -h..<h
        arkon.position = CGPoint.random(xRange: xRange, yRange: yRange)
        arkon.zRotation = CGFloat.random(in: 0..<CGFloat.tau)

        // The physics engine becomes unhappy if we add the arkon to the portal
        // in the wrong phase of the display cycle, which happens because we're
        // running all this setup on a work queue rather than in the main display
        // update. So instead of adding in this context, we hand off an action to
        // the portal and let him add us when it's safe.
        let action = SKAction.run {
            //            print("adding", arkon.scab.fishNumber)
            portal.addChild(arkon)
            arkon.addChild(nose)

            // Surprisingly, the physics engine also becomes unhappy if we add
            // the physics bodies before we add their owning nodes to the scene.
            arkon.physicsBody = pBody
            nose.physicsBody = nosePBody

            arkon.senseLoader = SenseLoader(arkon)

            nosePBody.pinned = true // It wouldn't do to leave our senses behind
        }

        portal.run(action, completion: {
            arkon.isReadyForTick = true
            arkon.isAlive = true
        })

        //        print("doe")
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

    static private func setupNose() -> KNoseNode {
        let nose = KNoseNode(
            texture: ArkonCentralLight.topTexture,
            color: .green,
            size: ArkonCentralLight.topTexture!.size()
        )

        nose.name = "nose_awaiting_fish_number"
        nose.setScale(0.5)
        nose.color = .blue
        nose.colorBlendFactor = 1.0
        nose.zPosition = ArkonCentralLight.vArkonZPosition + 1

        return nose
    }
}
