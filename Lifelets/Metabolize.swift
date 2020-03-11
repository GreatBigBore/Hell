import GameplayKit

final class Metabolize: Dispatchable {
    internal override func launch() { aMetabolize() }
}

extension Metabolize {
    func aMetabolize() {
        guard let (ch, dp, st) = scratch?.getKeypoints() else { fatalError() }
        assert(st.sprite === st.gridCell.sprite)
        Debug.log(level: 71) { "Metabolize \(six(st.name))" }

        if Arkonia.debugColorIsEnabled { st.sprite.color = .red }

        st.metabolism.metabolizeProper(ch.co2Counter > 0, st.nose)

        dp.colorize()
    }
}

extension Metabolism {
    fileprivate func metabolizeProper(_ isStarving: Bool, _ nose: SKSpriteNode) {
        nose.color = .green
        nose.colorBlendFactor = min(fungibleEnergyFullness * 2, 1)

        let stomachToReady = !stomach.isEmpty && !readyEnergyReserves.isFull

        if stomachToReady {
            let transfer = stomach.withdraw(Arkonia.energyTransferRateInJoules)
            readyEnergyReserves.deposit(transfer)
        }

        let readyToFat = readyEnergyReserves.isAmple && !fatReserves.isFull

        if readyToFat {
            let surplus_ = readyEnergyReserves.level - readyEnergyReserves.overflowThreshold
            let surplus = min(surplus_, Arkonia.energyTransferRateInJoules)
            let net = readyEnergyReserves.withdraw(surplus)
            fatReserves.deposit(net)
        }

        let tapFatReserves = (readyEnergyReserves.level < reUnderflowThreshold)

        if tapFatReserves {
            let refill = fatReserves.withdraw(Arkonia.energyTransferRateInJoules)
            readyEnergyReserves.deposit(refill)
        }

        let fatToSpawn = fatReserves.isAmple && !spawnReserves.isFull

        if fatToSpawn {
            let transfer = fatReserves.withdraw(Arkonia.energyTransferRateInJoules)
            spawnReserves.deposit(transfer)
        }
    }
}
