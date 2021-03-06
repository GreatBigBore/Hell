import CoreGraphics

class DriveResponse {
    enum MotorIndex: Int, CaseIterable { case jumpSelector, jumpSpeed }

    let net: Net
    let stepper: Stepper

    init(_ stepper: Stepper) { self.stepper = stepper; self.net = stepper.net }

    func driveResponse(
        _ senseData: UnsafeMutablePointer<Float>,
        _ onComplete: @escaping (Bool) -> Void
    ) { net.driveSignal { self.driveResponse_B(senseData, onComplete) } }

    private func driveResponse_B(
        _ senseData: UnsafeMutablePointer<Float>,
        _ onComplete: @escaping (Bool) -> Void
    ) { mainDispatch { self.driveResponse_C(senseData, onComplete) } }

    private func driveResponse_C(
        _ senseData: UnsafeMutablePointer<Float>,
        _ onComplete: @escaping (Bool) -> Void
    ) {
        Debug.log(level: 213) { "driveResponse_C.0 \(stepper.name)" }
        let cSensorPadCells = net.netStructure.sensorPadCCells

        // Divide the circle into cCellsWithinSenseRange slices
        let s0 = net.pMotorOutputs[MotorIndex.jumpSelector.rawValue]
        let s1 = s0 * Float(cSensorPadCells)
        let s2 = floor(s1)
        let s3 = Int(s2)

        // In case we get a 1.0 -- that would push us beyond the end of the array
        let targetOffset = (s3 == cSensorPadCells) ? cSensorPadCells - 1 : s3

        driveResponse_C1(senseData, targetOffset) { okToJump in
            mainDispatch { onComplete(okToJump) }
        }
    }

    private func driveResponse_C1(
        _ senseData: UnsafeMutablePointer<Float>,
        _ targetOffset: Int,
        _ onComplete: @escaping (Bool) -> Void
    ) {
        assert(stepper.jumpSpec == nil)
        let jumpSpeedMotorOutput = stepper.net.pMotorOutputs[MotorIndex.jumpSpeed.rawValue]
        let onJump   = {
            Debug.log(level: 213) { "driveResponse_C1.X1 jump" }
            onComplete(true) }
        let onNoJump = {
            Debug.log(level: 213) { "driveResponse_C1.X2 no jump" }
            onComplete(false) }

        Debug.log(level: 213) { "driveResponse_C1.X3 targetOffset \(targetOffset)" }

        if targetOffset > 0 {
            guard let correctedTarget = stepper.sensorPad.getFirstTargetableCell(
                startingAt: targetOffset
            ) else {
                // If we couldn't find a cell to jump to (which would be a really
                // crowded situation), then just sit this one out
                Debug.log(level: 215) { "driveResponse_C1 no jump possible; original targetOffset \(targetOffset)" }
                onNoJump(); return
            }

            assert(stepper.spindle.gridCell.lock.isLocked)
            stepper.jumpSpec = JumpSpec(
                from: stepper.spindle.gridCell!, to: correctedTarget,
                speedAsPercentage: max(CGFloat(jumpSpeedMotorOutput), 0.1)
            )

            Debug.log(level: 215) {
                let js = stepper.jumpSpec!

                return "JumpSpec("
                    + "\(AKName(stepper.name))"
                    + " from: \(js.from.properties)"
                    + ", to: \(js.to.cellSS.properties)"
                    + ")"
            }

            // All done with most of the sensor pad. All we need now is the
            // shuttle; free up everything else for the other arkons
            stepper.sensorPad.refractorizeSensors(stepper.jumpSpec)

            self.driveResponse_D(onJump)
            return
        }

        Debug.log(level: 215) { "driveResponse_C1 \(AKName(stepper.name)) no jump \(stepper.spindle.gridCell.properties)" }
        onNoJump()
    }

    private func driveResponse_D(_ onSuccess: @escaping () -> Void) {
        let isAlive = stepper.metabolism.applyJumpCosts(stepper.jumpSpec!)

        Debug.log(level: 213) { "driveResponse_D.0 \(stepper.name)" }
        if isAlive { onSuccess(); return }

        Debug.log(level: 213) { "driveResponse_D.1 \(stepper.name)" }

        stepper.apoptosize(disengageAll: false)
    }
}
