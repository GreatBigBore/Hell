import Dispatch

final class Engage: Dispatchable {
    internal override func launch() { Grid.arkonsPlaneQueue.async { self.engage(.arkonsPlane) } }

    private func engage(_ catchDumbMistakes: DispatchQueueID) {
        assert(scratch.engagerKey == nil)

        Debug.log(level: 168) { "Engage \(six(scratch.stepper.name)) at \(scratch.stepper.gridCell.gridPosition)" }
        Debug.debugColor(scratch.stepper, .magenta, .magenta)

        let isEngaged = self.engageIf(catchDumbMistakes)
        guard isEngaged else {
            Debug.log(level: 168) { "Engage failed for \(six(scratch.stepper.name))" }
            return
        }

        self.makeSenseGrid(catchDumbMistakes)
        scratch.dispatch!.tickLife()
    }

    private func engageIf(_ catchDumbMistakes: DispatchQueueID) -> Bool {
        assert(scratch.engagerKey == nil)

        guard let gc = scratch.stepper.gridCell else { fatalError() }

        if let ek = gc.getLock(for: scratch.stepper, .degradeToCold, catchDumbMistakes) as? GridCell
            { scratch.engagerKey = ek; return true }

        return false
    }

    private func makeSenseGrid(_ catchDumbMistakes: DispatchQueueID) {
        guard let hk = scratch.engagerKey else { fatalError() }

        Debug.log(level: 167) {
            "senseGrid.0 for \(scratch.stepper.name) at \(hk.gridPosition)"
        }

        scratch.senseGrid = CellSenseGrid(
            from: hk, by: Arkonia.cSenseGridlets, block: scratch.stepper.previousShiftOffset, catchDumbMistakes
        )

        #if DEBUG
        Debug.log(level: 167) {
            let m: [String] = scratch.senseGrid!.cells.map { cell in
                let key: String

                switch cell {
                case is GridCell: key = "hot"
                case is ColdKey:  key = "cold"
                case is NilKey:   key = "nil"

                default: fatalError()
                }

                return "\(key)\(cell.gridPosition)"
            }

            return "senseGrid.1 for \(scratch.stepper.name) \(m)"
        }
        #endif
    }
}

extension GridCell {
    func getLock(for stepper: Stepper, _ require: RequireLock, _ catchDumbMistakes: DispatchQueueID) -> GridCellProtocol? {
        let key = lock(require: require, ownerName: stepper.name, catchDumbMistakes)

        #if DEBUG
        Debug.log(level: 167) { "getLock4 for \(six(stepper.name))" }
        #endif

        if key is ColdKey {
            #if DEBUG
            Debug.log(level: 167) { "getLock4.5 for \(six(stepper.name))" }
            #endif

            assert(isLocked && ownerName != stepper.name)
            reschedule(stepper, catchDumbMistakes)
        }

        return key
    }
}
