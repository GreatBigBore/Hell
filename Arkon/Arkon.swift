import Foundation
import SpriteKit

struct Selectoid {
    static var TheFishNumber = 0

//    let birthday: TimeInterval
//    var cOffspring: Int
    let fishNumber: Int
//    let fishNumberOfParent: Int?
//    let genome: [GeneProtocol]
//    let genomeOfParent: [GeneProtocol]?

    init() {
        defer { Selectoid.TheFishNumber += 1 }
        fishNumber = Selectoid.TheFishNumber
    }
}

extension SKPhysicsBody: Massive {}

class Arkon {
    let metabolism: Metabolism
    let nose: SKSpriteNode
    var selectoid = Selectoid()
    var scene: SKSpriteNode { return Arkon.portal! }
    let sprite: SKSpriteNode
    var spriteFactory: SpriteFactory { return Arkon.spriteFactory! }

    init() {
        sprite = Arkon.spriteFactory!.arkonsHangar.makeSprite()
        sprite.setScale(0.5)
        sprite.color = .green
        sprite.colorBlendFactor = 1

        let spritePhysicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)

        spritePhysicsBody.categoryBitMask = ArkoniaCentral.PhysicsBitmask.arkonBody.rawValue
        spritePhysicsBody.collisionBitMask = ArkoniaCentral.PhysicsBitmask.arkonBody.rawValue

        spritePhysicsBody.contactTestBitMask =
            ArkoniaCentral.PhysicsBitmask.arkonBody.rawValue |
            ArkoniaCentral.PhysicsBitmask.mannaBody.rawValue

        spritePhysicsBody.mass = 1

        nose = Arkon.spriteFactory!.noseHangar.makeSprite()
        nose.color = .magenta
        nose.colorBlendFactor = 1

        let nosePhysicsBody = SKPhysicsBody(circleOfRadius: nose.size.width)

        nosePhysicsBody.categoryBitMask = ArkoniaCentral.PhysicsBitmask.arkonSenses.rawValue
        nosePhysicsBody.collisionBitMask = 0

        nosePhysicsBody.contactTestBitMask =
            ArkoniaCentral.PhysicsBitmask.arkonBody.rawValue |
            ArkoniaCentral.PhysicsBitmask.mannaBody.rawValue

        nosePhysicsBody.mass = 0.1
        nosePhysicsBody.pinned = true

        metabolism = Metabolism(spritePhysicsBody)

        let w = Arkon.portal!.size.width / 2
        let h = Arkon.portal!.size.height / 2

        let xRange = -w..<w
        let yRange = -h..<h

        sprite.position = CGPoint.random(xRange: xRange, yRange: yRange)
        sprite.addChild(nose)
        scene.addChild(sprite)

        sprite.physicsBody = spritePhysicsBody
        nose.physicsBody = nosePhysicsBody
    }
}

extension Arkon {
    static var arkonHangar = [Int: Arkon]()
    static var portal: SKSpriteNode?
    static var spriteFactory: SpriteFactory?

    static func getActions(sprite: SKSpriteNode, maneuvers: Maneuvers) -> SKAction {
        let actions = SKAction.sequence([
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [1, 0, 1, 0, 0]),  // thrust
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [0.5, 0, 0, 0, 1]),  // wait
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [1, 1, 0, 0, 0]),  // stop
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [0.5, 0, 0, 0, 1]),  // wait
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [1, 0, 0, 1, 0]),  // rotate
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [0.5, 0, 0, 0, 1]),  // wait
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [1, 1, 0, 0, 0]),  // stop
            maneuvers.selectActionPrimitive(arkon: sprite, motorOutputs: [0.5, 0, 0, 0, 1])  // wait
        ])

        return actions
    }

    static func grazeTest() {
        for a in 0..<1 {
            let newArkon = Arkon()
            arkonHangar[a] = newArkon

            onePass(sprite: newArkon.sprite, metabolism: newArkon.metabolism)
        }
    }

    static func inject(_ spriteFactory: SpriteFactory, _ portal: SKSpriteNode) {
        Arkon.spriteFactory = spriteFactory
        Arkon.portal = portal
    }

    static func onePass(sprite: SKSpriteNode, metabolism: Metabolism) {
        let nose = (sprite.children[0] as? SKSpriteNode)!
        nose.color = ColorGradient.makeColor(Int(metabolism.energyFullness * 100), 100)

        let maneuvers = Maneuvers(energySource: metabolism)
        let actions = getActions(sprite: sprite, maneuvers: maneuvers)

//        print("nass", sprite.physicsBody!.mass, metabolism.energyFullness)//, nosePhysicsBody.mass)

        sprite.run(actions) { onePass(sprite: sprite, metabolism: metabolism) }
    }
}
