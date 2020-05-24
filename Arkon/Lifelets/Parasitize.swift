import SpriteKit

final class Parasitize: Dispatchable {

    internal override func launch() { Parasitize.parasitize(scratch, .unspecified) }
}

extension Parasitize {
    static func parasitize(_ attackerScratch: Scratchpad, _ catchDumbMistakes: DispatchQueueID) {
        Debug.log(level: 156) { "Parasitize; attacker is \(six(attackerScratch.stepper.name))" }
        Debug.debugColor(attackerScratch.stepper, .brown, .red)

        var victor: Stepper?, victim: Stepper?

        func a() {
            attackAfterLockingPlane(by: attackerScratch) { (victor, victim) = ($0, $1); b() }
        }

        func b() {
            let winner = (victor)!
            let loser = (victim)!

            Debug.debugColor(loser, .blue, .magenta)
            Debug.debugColor(winner, .blue, .orange)

            dieHorribly(loser.sprite, c)
        }

        func c() {
            let winner = (victor)!
            let loser = (victim)!

            parasitize(winner, loser, catchDumbMistakes) {}
        }

        a()
    }
}

extension Parasitize {
    private static let big = Arkonia.arkonScaleFactor * 3 / Arkonia.zoomFactor
    private static let small = Arkonia.arkonScaleFactor / Arkonia.zoomFactor
    private static let d = 0.1

    private static let bleedToDeath = SKAction.colorize(with: .red, colorBlendFactor: 1, duration: d)
    private static let deelbToDeath = SKAction.colorize(with: .white, colorBlendFactor: 0, duration: d)
    private static let sequence = SKAction.sequence([bleedToDeath, deelbToDeath])
    private static let makeAScene = SKAction.repeat(sequence, count: 5)

    static func dieHorribly(_ sprite: SKSpriteNode, _ onComplete: @escaping () -> Void) {
        sprite.run(makeAScene, completion: onComplete)
    }
}

extension Parasitize {
    static func attackAfterLockingPlane(
        by scratch: Scratchpad, _ onComplete: @escaping (Stepper, Stepper) -> Void
    ) {
        Grid.arkonsPlaneQueue.async {
            attackOnLockedPlane(scratch: scratch, .arkonsPlane) { victor, victim in onComplete(victor, victim) }
        }
    }

    private static func attackOnLockedPlane(
        scratch myScratch: Scratchpad, _ catchDumbMistakes: DispatchQueueID,
        _ onComplete: @escaping (Stepper, Stepper) -> Void
    ) {
        Debug.debugColor(myScratch.stepper, .blue, .purple)

        let hisStepper = (myScratch.cellShuttle?.toCell?.stepper)!

        hardAssert(hisStepper !== myScratch.stepper, "hardAssert at \(#file):\(#line)")
        hardAssert(hisStepper.name != myScratch.stepper.name, "hardAssert at \(#file):\(#line)")

        let myMass = myScratch.stepper.metabolism.mass
        let hisMass = hisStepper.metabolism.mass

        if myMass > (hisMass * 1.25) {
            myScratch.stepper.isTurnabouted = false
            hisStepper.isTurnabouted = false

            myScratch.stepper.gridCell.descheduleIf(hisStepper, catchDumbMistakes)

            onComplete(myScratch.stepper, hisStepper)
        } else {
            myScratch.stepper.isTurnabouted = true
            hisStepper.isTurnabouted = true

            let hisScratch = hisStepper.dispatch.scratch
            let myShuttle = (myScratch.cellShuttle)!

            myShuttle.transferKeys(to: hisStepper, catchDumbMistakes) {
                hardAssert(hisScratch!.engagerKey == nil, "hardAssert at \(#file):\(#line)")

                hisScratch!.cellShuttle = $0
                myScratch.cellShuttle = nil

                Debug.log(level: 104) {
                    "me \(six(myScratch.name)) -> nil true, him \(six(hisScratch!.name)) -> nil \(hisScratch!.cellShuttle == nil)"
                }

                myScratch.stepper.gridCell.descheduleIf(hisStepper, catchDumbMistakes)

                onComplete(hisStepper, myScratch.stepper)
            }
        }
    }

    static func parasitize(
        _ victor: Stepper, _ victim: Stepper, _ catchDumbMistakes: DispatchQueueID, _ onComplete: @escaping () -> Void
    ) {
        Debug.log(level: 109) { "victor \(victor.name) eats \(victim.name) at \(victor.gridCell.gridPosition)/\(victim.gridCell.gridPosition)" }
        Grid.arkonsPlaneQueue.async {
            victor.metabolism.parasitizeProper(victim)
            victor.dispatch.releaseShuttle()

            Debug.log(level: 109) { "set4 \(six(victim.name))" }
            if let ek = victim.dispatch.scratch.engagerKey { ek.releaseLock(catchDumbMistakes) }
            victim.gridCell = nil   // Victor now owns the cell
            victim.dispatch.apoptosize()

            onComplete()
        }
    }
}

extension Metabolism {
    func parasitizeProper(_ victim: Stepper) {
//        let spareCapacity = stomach.capacity - stomach.level
//        let victimEnergy = victim.metabolism.withdrawEnergy(spareCapacity)
//        let netEnergy = victimEnergy * 0.25

//        absorb(
//            Manna.Nutrition(
//                victim.metabolism.bone.vitaminLevel, netEnergy,
//                victim.metabolism.leather.vitaminLevel, victim.metabolism.lungs.level,
//                victim.metabolism.poison.vitaminLevel
//            )
//        )
    }
}