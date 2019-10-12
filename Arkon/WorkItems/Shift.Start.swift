import Foundation

class Shift {
    var sensoryInputs = [(Double, Double)]()
    var shifting = false
    var shifting2 = false
    weak var stepper: Stepper?
    var usableGridOffsets = [AKPoint]()

    init(stepper: Stepper) { self.stepper = stepper }
}

extension Shift {
    func start(_ gridlet: Gridlet, completion: @escaping CoordinatorCallback) {
        let workItem = { [unowned self] in
            assert(self.shifting == false)
            defer { self.shifting = false }
            self.shifting = true
            self.start_(gridlet)
        }

        Lockable<Void>().lockWorld(workItem, completion)
    }

    private func start_(_ gridlet: Gridlet) {
        reserveGridPoints(gridlet)
        loadGridInputs(gridlet)
    }

    private func loadGridInputs(_ gridlet: Gridlet) {
        sensoryInputs = Stepper.gridInputs.map { step in

            let inputGridlet = step + gridlet.gridPosition

            if Gridlet.isOnGrid(inputGridlet.x, inputGridlet.y) {
                let targetGridlet = Gridlet.at(inputGridlet)

                let contents = Gridlet.at(inputGridlet).contents
                let rvContents = contents.rawValue
                let nutrition: Double
                switch contents {
                case .arkon:
                    nutrition = Double(targetGridlet.sprite?.stepper.metabolism.energyFullness ?? 0)

                case .manna:
                    nutrition = Double(targetGridlet.sprite?.manna.energyContentInJoules ?? 0)

                case .nothing:
                    nutrition = 0
                }

                return (rvContents, nutrition)
            }

            return (Gridlet.Contents.nothing.rawValue, -1e6)
        }
    }

//    func reserveGridPoints_(
//        _ gridlet: Gridlet,
//        completion: @escaping Lockable<Void>.LockWorldCompletion
//    ) {
//        Lockable<Void>().lockWorld(
//            { self.reserveGridPoints_(gridlet) }, completion
//        )
//    }

    private func reserveGridPoints(_ gridlet: Gridlet) {
        usableGridOffsets = Stepper.moves.compactMap { offset in

            let targetGridPoint = gridlet.gridPosition + offset
            if Gridlet.isOnGrid(targetGridPoint.x, targetGridPoint.y) {
                let targetGridlet = Gridlet.at(targetGridPoint)

                if targetGridlet.gridletIsEngaged { return nil }

                // If there's no arkon in our target cell, then we
                // can go there if we want
                if targetGridlet.contents != .arkon {
                    targetGridlet.gridletIsEngaged = true
                    return offset
                }

                guard let intendedVictim = targetGridlet.sprite?.stepper else { fatalError() }

                if !intendedVictim.isAlive { return nil }

                // Not sure about this one; seems like it wouldn't be good for
                // us to be mussing about with other arkons while actions are
                // running?
                assert(Display.displayCycle != .actions)
                if Display.displayCycle == .actions { return nil }

                defer {
                    intendedVictim.stepperIsEngaged = true
                    targetGridlet.gridletIsEngaged = true
                }

                // If there's an arkon in our target cell that isn't engaged,
                // we can go attack it if we want
                if !intendedVictim.stepperIsEngaged { return offset }
            }

            return nil
        }
    }
}
