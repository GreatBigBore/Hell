import SpriteKit

extension Stepper {
    func parasitize() {

        Debug.log(level: 220) {
            "Attack ix \(jumpSpec!.attackTargetIndex)"
            + " jump from \(jumpSpec!.from.properties.gridPosition)"
            + " to \(Grid.cellAt(jumpSpec!.to.cellSS.properties.gridPosition))"
        }

        let (attackTargetCell, attackTargetGridPosition) = Grid.cellAt(
            jumpSpec!.attackTargetIndex, from: Grid.cellAt(jumpSpec!.to.cellSS.properties.gridAbsoluteIndex)
        )

        assert(attackTargetGridPosition != self.spindle.gridCell.properties.gridPosition)

        if isWithinSensorRange(attackTargetGridPosition) &&
            isLockedByMe(attackTargetCell) &&
            hasArkon(attackTargetCell) {

            Debug.log(level: 220) {
                "Parasitizing at \(attackTargetGridPosition)"
            }

            guard let spindle = attackTargetCell.contents.arkon else {
                Debug.log(level: 220) { "no spindle?" }
                fatalError()
            }

            guard let victim = spindle.arkon else {
                Debug.log(level: 221) { "no arkon?" }
                fatalError()
            }

            assert(victim !== self)

            parasitize_B(victim)
            return
        }

        Debug.log(level: 221) {
            var message = "parasitize: \(AKName(self.name))"
            + " can't eat arkon at \(attackTargetGridPosition)"
            + ": inRange: \(isWithinSensorRange(attackTargetGridPosition))"

            if isWithinSensorRange(attackTargetGridPosition) {
                message += ", locked by me: \(isLockedByMe(attackTargetCell))"

                if isLockedByMe(attackTargetCell) {
                    message += ", an arkon is there: \(hasArkon(attackTargetCell))"
                }
            }

            return message
        }

        disengageGrid()
    }

    private func parasitize_B(_ victim: Stepper) {
        let swell = SKAction.scale(by: 1.3, duration: 0.05)
        let shrink = swell.reversed()
        let sequence = SKAction.sequence([swell, shrink])
        let `repeat` = SKAction.repeat(sequence, count: 8)
        thorax.run(`repeat`) { self.parasitize_C(victim) }
    }

    private func parasitize_C(_ victim: Stepper) {
        let debugix = self.getLocalIndexForCell(victim.spindle.gridCell)

        // Victim will see this when he wakes up, then he'll die
        victim.isDyingFromParasite = true

        mainDispatch {
            Debug.log(level: 220) {
                return "parasitize: \(AKName(self.name))"
                    + " devours \(AKName(victim.name))"
                    + "; jumped from \(self.jumpSpec!.from.properties.gridPosition)"
                    + " to \(self.jumpSpec!.to.cellSS.properties.gridPosition)"
                    + " attacking index \(debugix))"
            }
        }
    }
}

func abs(_ position: AKPoint) -> AKPoint {
    AKPoint(x: abs(position.x), y: abs(position.y))
}

private extension Stepper {
    func getLocalIndexForCell(_ cell: GridCell) -> Int {
        let fromGridPosition = jumpSpec!.from.properties.gridPosition
        let offset = abs(cell.properties.gridPosition) - abs(fromGridPosition)

        Debug.log(level: 219) {
            "getLocalIndexForCell(\(cell.properties.gridPosition))"
            + "; from = \(fromGridPosition)"
            + "; offset = \(offset)"
        }

        return GridIndexer.offsetToLocalIndex(offset)
    }

    func hasArkon(_ cell: GridCell) -> Bool { cell.contents.hasArkon() }

    func isLockedByMe(_ cell: GridCell) -> Bool {
        let localIndex = getLocalIndexForCell(cell)
        return sensorPad.theSensors[localIndex].iHaveTheLiveConnection
    }

    func isWithinSensorRange(_ gridPosition: AKPoint) -> Bool {
        let offset = gridPosition - jumpSpec!.from.properties.gridPosition
        let maxOffset = net.netStructure.cSenseRings
        return abs(offset.x) <= maxOffset  && abs(offset.y) <= maxOffset
    }
}
