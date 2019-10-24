import CoreGraphics
import Foundation

extension Stepper {
    func funge() {
        World.lock(getAge_, relay_, .continueBarrier)
    }

    func getAge_() -> [TimeInterval]? {
        let age = World.shared.getCurrentTime_() - birthday
        return [age]
    }

    func relay_(_ ages: [TimeInterval]?) {
        guard let age = ages?[0] else { fatalError() }
        metabolism.funge(parentStepper, age: age)
    }
}

extension Metabolism {

    func funge(_ parentStepper: Stepper?, age: TimeInterval) {

        World.lock({ () -> [Bool]? in

            let isAlive = self.funge_(age: age)
            return [isAlive]

        }, { (_ isAlives: [Bool]?) in

            guard let isAlive = isAlives?[0] else { fatalError() }
            let af = ArkonFactory(parentStepper)

            if isAlive { af.spawnCommoner() }
            else       { parentStepper!.apoptosize() }
        },
           .continueBarrier
        )
    }

    private func funge_(age: TimeInterval) -> Bool {
        let fudgeFactor: CGFloat = 1
        let joulesNeeded = fudgeFactor * mass

        withdrawFromReady(joulesNeeded)

        let oxygenCost: TimeInterval = age < TimeInterval(5) ? 0 : 1
        oxygenLevel -= (CGFloat(oxygenCost) / 60.0)

        return fungibleEnergyFullness > 0 && oxygenLevel > 0
    }
}
