import Foundation

class Shift {
    weak var dispatch: Dispatch!
    var runningAsBarrier: Bool { return dispatch.runningAsBarrier }
    var sensoryInputs = [(Double, Double)]()
    var stepper: Stepper { return dispatch.stepper }
    var usableGridOffsets = [AKPoint]()

    init(_ dispatch: Dispatch) {
        self.dispatch = dispatch
    }

    func go() {
        dispatch.go({ self.aShift() }, runAsBarrier: true)
    }

}

extension Shift {
    func aShift() {
        assert(dispatch.runningAsBarrier == true)
        setupGrid()
        dispatch.calculateShift()
    }

    func setupGrid() {
        reserveGridPoints()
        loadGridInputs()
    }

    private func loadGridInputs() {
        assert(runningAsBarrier == true)

        sensoryInputs = Grid.gridInputs.map { step in
            return self.loadGridInputs_(step)
        }
    }

    private func reserveGridPoints() {
        assert(runningAsBarrier == true)
        usableGridOffsets = Grid.moves.compactMap { offset in
            reserveGridPoints_(offset)
        }
    }
}

extension Shift {

    private func loadGridInputs_(_ step: AKPoint) -> (Double, Double) {
        assert(runningAsBarrier == true)

        let inputGridlet = step + stepper.gridlet.gridPosition
        if !Gridlet.isOnGrid(inputGridlet.x, inputGridlet.y) {
            return (Gridlet.Contents.nothing.rawValue, -1e6)
        }

        let targetGridlet = Gridlet.at(inputGridlet)

        let nutrition: Double

        switch targetGridlet.contents {
        case .arkon:
            nutrition = Double(stepper.metabolism.energyFullness)

        case .manna:
            let sprite = targetGridlet.sprite!
            let manna = Manna.getManna(from: sprite)
            nutrition = Double(manna.energyContentInJoules)

        case .nothing:
            nutrition = 0
        }

        return (targetGridlet.contents.rawValue, nutrition)
    }

    func reserveGridPoints_(_ offset: AKPoint) -> AKPoint? {
        assert(runningAsBarrier == true)

        let targetGridPoint = stepper.gridlet.gridPosition + offset

        if Gridlet.isOnGrid(targetGridPoint.x, targetGridPoint.y) {
            let targetGridlet = Gridlet.at(targetGridPoint)

            if !targetGridlet.gridletIsEngaged {
                targetGridlet.gridletIsEngaged = true
                return offset
            }
        }

        return nil
    }
}
