import CoreGraphics

extension Plotter {
    func setRoute(
        _ senseData: [Double], _ senseGrid: CellSenseGrid, _ onComplete: @escaping (CellShuttle) -> Void
    ) {
        guard let scratch = scratch else { fatalError() }
        guard let stepper = scratch.stepper else { fatalError() }
        guard let net = stepper.net else { fatalError() }

        Debug.log(level: 119) { "makeCellShuttle for \(six(stepper.name)) from \(stepper.gridCell!)" }
        Debug.log(level: 122) { "senseData \(senseData)" }

        var motorOutputs = [(Int, Double)]()

        func a() {
            net.getMotorOutputs(senseData) { rawOutputs in
                Debug.log(level: 145) { "rawOutputs \(rawOutputs)" }

                motorOutputs = zip(0..., rawOutputs).compactMap { position, rawOutput in
                    (position, rawOutput)
                }

                // Get off the computation thread as quickly as possible
                Dispatch.dispatchQueue.async(execute: b)
            }
        }

        func b() {
            let motorOutput_ = motorOutputs[0].1

            // Divide the circle into cMotorGridlets + 1 slices
            let s0 = motorOutput_
            let s1 = s0 * Double(Arkonia.cMotorGridlets + 1)
            let s2 = floor(s1)
            let s3 = Int(s2)
            let motorOutput = s3
            Debug.log(level: 154) { "motorOutput \(motorOutputs) -> \(motorOutput)" }

            let targetOffset = calculateTargetOffset(for: motorOutput, from: senseGrid.cells)

            Debug.log(level: 154) { "toff \(targetOffset) from motorOutput \(motorOutput)" }

            guard let toCell = senseGrid.cells[targetOffset] as? GridCell else { fatalError() }
            let fromCell = (targetOffset > 0) ? senseGrid.cells[0] as? GridCell : nil

            if targetOffset == 0 { Debug.log(level: 167) { "targetOffset \(targetOffset) \(six(toCell))" } }
            else { Debug.log(level: 167) { "from \(six(fromCell)) to targetOffset \(targetOffset) \(six(toCell))" } }

            onComplete(CellShuttle(fromCell, toCell))
        }

        a()
    }

    func calculateTargetOffset(for motorOutput: Int, from cells: [GridCellProtocol]) -> Int {
        for c in cells {
            assert((c is GridCell) == (c.ownerName == cells[0].ownerName))
            assert(((c as? GridCell)?.isLocked ?? false) || !(c is GridCell))
        }

        // Try to use the selected motor output, ie, jump to that square on
        // the grid. But if that square is occupied, lay out a selection array
        // that makes "stand still" the least likely option. If the motor
        // output is 0 already, we just take it as is.
        //
        // Say we have 9 squares, meaning the 0 square where we are right now, and
        // the 8 around us. If the motor output is 3, then we set up the selection
        // array like 3, 4, 5, 6, 7, 8, 9, 1, 2, 0
        //

        for m in 0..<Arkonia.cMotorGridlets {
            let select = (m + motorOutput) % Arkonia.cMotorGridlets
            if select == 0 { continue }

            if cells[select] is GridCell &&
                (cells[select].stepper == nil || select == 0) {
                return select
            }
        }

        return 0
    }
}
