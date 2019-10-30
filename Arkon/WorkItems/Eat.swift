import SpriteKit

final class Eat: Dispatchable {
    enum Phase { case chooseEdible, settleCombat }

    var combatOrder: (Stepper, Stepper)!
    weak var dispatch: Dispatch!
    var gridlet: Gridlet!
    var manna: Manna!
    var phase = Phase.chooseEdible
    var runningAsBarrier: Bool { return dispatch.runningAsBarrier }
    var stepper: Stepper { return dispatch.stepper }

    init(_ dispatch: Dispatch) {
        self.dispatch = dispatch
    }

    func go() { aEat() }

    func inject(_ gridlet: Gridlet) { self.gridlet = gridlet }

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
    //swiftlint:disable function_body_length
    private func aEat() {
        assert(runningAsBarrier == true)

        switch phase {
        case .chooseEdible:

            switch dispatch.stepper.gridlet.contents {
            case .arkon:
                print(
                    "a",
                    dispatch.stepper.gridlet.previousContents,
                    dispatch.stepper.gridlet.contents,
                    dispatch.stepper.oldGridlet?.previousContents ?? .unknown,
                    dispatch.stepper.oldGridlet?.contents ?? .unknown
                )
                battleArkon()
                phase = .settleCombat
                dispatch.callAgain()

            case .manna:
                print(
                    "m",
                    dispatch.stepper.gridlet.previousContents,
                    dispatch.stepper.gridlet.contents,
                    dispatch.stepper.oldGridlet?.previousContents ?? .unknown,
                    dispatch.stepper.oldGridlet?.contents ?? .unknown
                )
                battleManna()
                phase = .settleCombat
                dispatch.defeatManna()

            case .nothing:
                print(
                    "n",
                    dispatch.stepper.gridlet.previousContents,
                    dispatch.stepper.gridlet.contents,
                    dispatch.stepper.oldGridlet?.previousContents ?? .unknown,
                    dispatch.stepper.oldGridlet?.contents ?? .unknown
                )
                dispatch.funge()

            case .unknown:
                print(
                    "u",
                    dispatch.stepper.gridlet.previousContents,
                    dispatch.stepper.gridlet.contents,
                    dispatch.stepper.oldGridlet?.previousContents ?? .unknown,
                    dispatch.stepper.oldGridlet?.contents ?? .unknown
                )
                dispatch.funge()
            }

        case .settleCombat:
            switch dispatch.stepper.gridlet.contents {
            case .arkon:
                settleCombat()

            case .manna:
                defeatManna()
                dispatch.funge()

            default: fatalError()
            }
        }
    }
    //swiftlint:enable function_body_length
}

extension Eat {
    func battleArkon() {
        assert(dispatch.runningAsBarrier == true)

        guard let otherSprite = dispatch.stepper.sprite,
            let otherUserData = otherSprite.userData,
            let otherAny = otherUserData[SpriteUserDataKey.stepper],
            let otherStepper = otherAny as? Stepper
        else { fatalError() }

        let myMass = dispatch.stepper.metabolism.mass
        let hisMass = otherStepper.metabolism.mass
        self.combatOrder = (myMass > (hisMass * 1.25)) ?
            (dispatch.stepper, otherStepper) : (otherStepper, dispatch.stepper)
    }

    func getResult() -> (Stepper, Stepper) {
        return combatOrder!
    }

    func battleManna() {

        guard let mannaSprite = dispatch.stepper.gridlet.sprite,
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
        let harvested = self.manna.harvest()
        stepper.metabolism.absorbEnergy(harvested)
        stepper.metabolism.inhale()
        MannaCoordinator.shared.beEaten(self.manna.sprite)
    }

    private func settleCombat() {
        self.combatOrder.0.dispatch.parasitize()
        self.combatOrder.1.dispatch.apoptosize()
    }
}
