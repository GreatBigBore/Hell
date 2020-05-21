import CoreGraphics

extension Plotter {

    enum MotorIndex: Int { case jumpSelector, jumpSpeed }

    func setRoute(
        _ senseData: [Double], _ senseGrid: CellSenseGrid,
        _ onComplete: @escaping (CellShuttle, Double) -> Void
    ) {
        let scratch = (self.scratch)!
        let stepper = (scratch.stepper)!
        let net = (stepper.net)!

        #if DEBUG
        Debug.log(level: 119) { "makeCellShuttle for \(six(stepper.name)) from \(stepper.gridCell!)" }
        Debug.log(level: 122) { "senseData \(senseData)" }
        #endif

        var motorOutputs = [Double]()

        func a() {
            net.getMotorOutputs(senseData) { motorOutputs = $0

                // Get off the computation thread as quickly as possible
                Dispatch.dispatchQueue.async(execute: b)
            }
        }

        func b() {
            // Divide the circle into cMotorGridlets + 1 slices
            let s0 = motorOutputs[MotorIndex.jumpSelector.rawValue]
            let s1 = s0 * Double(Arkonia.cMotorGridlets + 1)
            let s2 = floor(s1)
            let s3 = Int(s2)
            let motorOutput = s3

            let targetOffset = calculateTargetOffset(for: motorOutput, from: senseGrid.cells)

            let toCell = (senseGrid.cells[targetOffset] as? GridCell)!

            let fromCell = (targetOffset > 0) ? senseGrid.cells[0] as? GridCell : nil

            let jumpSpeedMotorOutput = motorOutputs[MotorIndex.jumpSpeed.rawValue]

            if let f = fromCell {
                let asPercentage = max(CGFloat(jumpSpeedMotorOutput), 0.1)
                let jumpDistanceInCells = f.gridPosition.asPoint().distance(to: toCell.gridPosition.asPoint())

                scratch.jumpSpec = JumpSpec(jumpDistanceInCells, asPercentage)

                let isAlive = stepper.metabolism.applyJumpCosts(scratch.jumpSpec)

                if !isAlive {
                    scratch.dispatch!.apoptosize()
                    return
                }
            }

            onComplete(CellShuttle(fromCell, toCell), jumpSpeedMotorOutput)
        }

        a()
    }

    func calculateTargetOffset(for motorOutput: Int, from cells: [GridCellProtocol]) -> Int {
        #if DEBUG
        for c in cells {
            hardAssert((c is GridCell) == (c.ownerName == cells[0].ownerName))
            hardAssert(((c as? GridCell)?.isLocked ?? false) || !(c is GridCell))
        }
        #endif

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
//            if select == 0 { continue }

            if cells[select] is GridCell &&
                (cells[select].stepper == nil || select == 0) {
                return select
            }
        }

//        return 0
        fatalError()
    }
}
