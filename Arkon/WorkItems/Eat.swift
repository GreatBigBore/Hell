import SpriteKit

final class Eat: AKWorkItem {
    enum Phase { case chooseEdible, settleCombat }

    var combatOrder: (Stepper, Stepper)!
    var currentGridlet: Gridlet!
    var manna: Manna!
    var phase = Phase.chooseEdible
    var previousGridlet: Gridlet?

    deinit {
        if let p = previousGridlet { p.releaseGridlet() }
    }

    func callAgain(_ phase: Phase, _ runType: Dispatch.RunType) {
        self.phase = phase
        self.runType = runType
        dispatch!.callAgain()
    }

    override func go() { aEat() }

    func inject(_ previousGridlet: Gridlet, _ currentGridlet: Gridlet) {
        self.previousGridlet = previousGridlet
        self.currentGridlet = currentGridlet
    }

    func inject(_ combatOrder: (Stepper, Stepper)) {
        self.combatOrder = combatOrder
        self.phase = .settleCombat
    }

    func inject(_ manna: Manna) {
        self.manna = manna
        self.phase = .settleCombat
    }
}

extension Eat {
    //swiftmint:disable function_body_length
    private func aEat() {
        guard let st = dispatch?.stepper else { fatalError() }
        switch phase {
        case .chooseEdible:

//            print("st1", st.gridlet.contents, st.gridlet.gridPosition)
            switch st.gridlet.contents {
            case .arkon:
                battleArkon()
                callAgain(.settleCombat, .barrier)

            case .manna:
                battleManna()
                callAgain(.settleCombat, .barrier)

            default: fatalError()
            }

        case .settleCombat:
//            print("st2", st.gridlet.contents, st.gridlet.gridPosition)
            switch st.gridlet.contents {
            case .arkon:
                settleCombat()

            case .manna:
                defeatManna()
                dispatch?.funge()

            default: fatalError()
            }
        }
    }
    //swiftmint:enable function_body_length
}

extension Eat {
    func battleArkon() {
        guard let dp = dispatch else { fatalError() }

        guard let otherSprite = previousGridlet?.sprite,
            let otherUserData = otherSprite.userData,
            let otherAny = otherUserData[SpriteUserDataKey.stepper],
            let otherStepper = otherAny as? Stepper
        else { fatalError() }

        let myMass = dp.stepper.metabolism.mass
        let hisMass = otherStepper.metabolism.mass
        print("combat: \(myMass) <-> \(hisMass)")

        self.combatOrder = (myMass > (hisMass * 1.25)) ?
            (dp.stepper, otherStepper) : (otherStepper, dp.stepper)
    }

    func getResult() -> (Stepper, Stepper) {
        return combatOrder!
    }

    func battleManna() {

        guard let mannaSprite = dispatch?.stepper.gridlet.sprite,
            let mannaUserData = mannaSprite.userData,
            let shouldBeManna = mannaUserData[SpriteUserDataKey.manna],
            let manna = shouldBeManna as? Manna
        else { fatalError() }

        self.manna = manna
    }

    func inject(_ any: Void?) { }
    func getResult() -> Manna { return manna }
}

extension Eat {
    private func defeatManna() {
        guard let st = stepper else { fatalError() }
        let harvested = self.manna.harvest()
        st.metabolism.absorbEnergy(harvested)
        st.metabolism.inhale()
        MannaCoordinator.shared.beEaten(self.manna.sprite)
    }

    private func settleCombat() {
        self.combatOrder.0.dispatch.parasitize()
        self.combatOrder.1.dispatch.apoptosize()
    }
}
