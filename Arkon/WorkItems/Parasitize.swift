import Foundation

final class Parasitize: Dispatchable {
    var scratch: Scratchpad?
    var wiLaunch: DispatchWorkItem?

    init(_ scratch: Scratchpad) {
        Log.L.write("Parasitize()", level: 22)
        self.scratch = scratch
        self.wiLaunch = DispatchWorkItem(block: launch_)
    }

    func launch_() {
        Log.L.write("Parasitize.launch_ \(six(scratch?.stepper?.name))", level: 22)
        let result = attack()
        parasitize(result.0, result.1)
    }
}

extension Parasitize {
    func attack() -> (Stepper, Stepper) {
        guard let (myScratch, _, myStepper) = scratch?.getKeypoints() else { fatalError() }

        guard let hisSprite = myScratch.getStageConnector(require: true)?.consumedSprite else { fatalError() }
        guard let hisStepper = hisSprite.getStepper() else { fatalError() }

        let myMass = myStepper.metabolism.mass
        let hisMass = hisStepper.metabolism.mass

        Log.L.write("Parasitize: \(six(myStepper.name)) attacks \(six(hisStepper.name))", level: 28)

        if myMass > (hisMass * 1.25) {
            Log.L.write("Parasitize2: \(six(myStepper.name)) eats \(six(hisStepper.name))", level: 28)
            myStepper.isTurnabouted = false
            hisStepper.isTurnabouted = false
            return (myStepper, hisStepper)
        } else {
            myStepper.isTurnabouted = true
            hisStepper.isTurnabouted = true
            Log.L.write("Parasitize3: \(six(myStepper.name)) eats \(six(hisStepper.name))", level: 28)

            let hisScratch = hisStepper.dispatch.scratch
            let myStageConnector = myScratch.getStageConnector()

            precondition(hisScratch.isEngaged == false)
            precondition(myStageConnector != nil)

            hisScratch.setGridConnector(myStageConnector)
            myScratch.resetGridConnector()

            precondition(hisScratch.getStageConnector() != nil)
            precondition(myScratch.isEngaged == false)

            return (hisStepper, myStepper)
        }
    }

    func parasitize(_ victor: Stepper, _ victim: Stepper) {
        victor.metabolism.parasitizeProper(victim)
        victor.dispatch.releaseStage()

        if victor.isTurnabouted {
            victim.nose.color = .yellow
            victim.dispatch.apoptosize()
        }
    }
}

extension Metabolism {
    func parasitizeProper(_ victim: Stepper) {
        let spareCapacity = stomach.capacity - stomach.level
        let victimEnergy = victim.metabolism.withdrawFromReady(spareCapacity)
        let netEnergy = victimEnergy * 0.25

        absorbEnergy(netEnergy)
        inhale()
    }
}
