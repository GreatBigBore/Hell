import Foundation

extension GridCell {
    func descheduleIf(_ stepper: Stepper, _ catchDumbMistakes: DispatchQueueID) {
        assert(catchDumbMistakes == .arkonsPlane)

        toReschedule.removeAll { waitingStepper in
            let remove = waitingStepper.name == stepper.name
            Debug.log(level: 169) { "deschedule \(six(stepper.name)) == \(six(waitingStepper.name))" }
            return remove
        }
    }

    func getRescheduledArkon(_ catchDumbMistakes: DispatchQueueID) -> Stepper? {
        assert(catchDumbMistakes == .arkonsPlane)

        #if DEBUG
        if !toReschedule.isEmpty {
            Debug.log(level: 168) {
                "getRescheduledArkon \(six(toReschedule.first!.name)) " +
                "\(toReschedule.count)"
            }
        }
        #endif

        defer { if toReschedule.isEmpty == false { _ = toReschedule.removeFirst() } }
        return toReschedule.first
    }

    func reengageRequesters(_ catchDumbMistakes: DispatchQueueID) {
        assert(catchDumbMistakes == .arkonsPlane)

        Debug.log(level: 169) {
            return self.toReschedule.isEmpty ? nil :
            "Reengage from \(self.toReschedule.map { $0.name }) at \(gridPosition)"
        }

        // Re-launch all rescheduled arkons before re-launching the manna
        while let waitingStepper = self.getRescheduledArkon(catchDumbMistakes) {
            if let dispatch = waitingStepper.dispatch {
                let scratch = dispatch.scratch
                assert(scratch!.engagerKey == nil)
                Debug.log(level: 169) { "reengageRequesters; disengage \(waitingStepper.name) at \(self.gridPosition)" }
                dispatch.disengage()
                return
            }

            Debug.log(level: 1698) { "reengageRequesters; no dispatch for \(waitingStepper.name) at \(self.gridPosition)" }
        }

        if self.mannaAwaitingRebloom {
            Debug.log(level: 168) { "reengageRequesters/rebloom manna at \(self.gridPosition)" }

            self.manna!.rebloom()
            self.mannaAwaitingRebloom = false
        }
    }

    func reschedule(_ stepper: Stepper, _ catchDumbMistakes: DispatchQueueID) {
        #if DEBUG
        assert(catchDumbMistakes == .arkonsPlane)

        // We shouldn't be here unless the lock attempt failed
        assert(self.isLocked && self.ownerName != .empty && self.ownerName != stepper.name)
        // The same arkon shouldn't be in here twice
        assert(toReschedule.contains { $0.name == stepper.name } == false)

        Debug.log(level: 169) {
            " Reschedule \(self.stepper!.name)"
            + " for cell \(self.gridPosition)"
            + " owned by \(self.ownerName)"
        }

        Grid.arkonsPlaneQueue.asyncAfter(deadline: .now() + TimeInterval(1)) { self.debugFoo() }

        Debug.debugColor(stepper, .blue, .red)
        #endif

        toReschedule.append(stepper)
        stepper.dispatch.scratch.isRescheduled = true   // Debug
    }

    func debugFoo() {
        if !self.toReschedule.isEmpty {
            Debug.log(level: 169) {
                "Still here:"
                + " reschedule \(self.stepper!.name)"
                + " for cell \(self.gridPosition)"
                + " owned by \(self.ownerName)"
            }
            Grid.arkonsPlaneQueue.asyncAfter(deadline: .now() + TimeInterval(1)) { self.debugFoo() }
        }
    }
}
