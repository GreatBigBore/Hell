import SpriteKit

class Metabolism {
    let allReserves: [EnergyReserve]
    let fungibleReserves: [EnergyReserve]
    let reUnderflowThreshold: CGFloat

    var oxygenLevel: CGFloat = 1.0

    var bone = EnergyReserve(.bone)
    var fatReserves = EnergyReserve(.fatReserves)
    var readyEnergyReserves = EnergyReserve(.readyEnergyReserves)
    var spawnReserves = EnergyReserve(.spawnReserves)
    var stomach = EnergyReserve(.stomach)

    var energyCapacity: CGFloat {
        return allReserves.reduce(0.0) { subtotal, reserves in
            subtotal + reserves.capacity
        }
    }

    var fungibleEnergyCapacity: CGFloat {
        return fungibleReserves.reduce(0.0) { subtotal, reserves in
            subtotal + reserves.capacity
        }
    }

    var energyContent: CGFloat {
        return allReserves.reduce(0.0) { subtotal, reserves in
            return subtotal + reserves.level
        }// + (muscles?.energyContent ?? 0)
    }

    var fungibleEnergyContent: CGFloat {
        return fungibleReserves.reduce(0.0) { subtotal, reserves in
            return subtotal + reserves.level
        }// + (muscles?.energyContent ?? 0)
    }

    var energyFullness: CGFloat { return energyContent / energyCapacity }

    var fungibleEnergyFullness: CGFloat { return fungibleEnergyContent / fungibleEnergyCapacity }

    var hunger: CGFloat { return 1 - energyFullness }

    var spawnEnergyFullness: CGFloat {
        return spawnReserves.level / spawnReserves.capacity }

    var mass: CGFloat {
        let m: CGFloat = self.allReserves.reduce(0.0) {
            subtotal, reserve in
            Debug.log("reserve \(reserve.name) level = \(reserve.level), reserve mass = \(reserve.mass)", level: 14)
            return subtotal + reserve.mass
        }

        Debug.log("mass: \(m)", level: 74)

        return m
    }

    var massCapacity: CGFloat {
        return allReserves.reduce(0) { subtotal, reserves in
            subtotal + (reserves.capacity / reserves.energyDensity)
        }
    }

    init() {
        self.allReserves = [bone, stomach, readyEnergyReserves, fatReserves, spawnReserves]
        self.fungibleReserves = [readyEnergyReserves, fatReserves]

        // Overflow is 5/6, make underflow 1/4, see how it goes
        self.reUnderflowThreshold = 1.0 / 4.0 * readyEnergyReserves.capacity

        Debug.log(
            "Metabolism():" +
            " mass \(String(format: "%-2.6f", mass))," +
            " O2 \(String(format: "%-3.2f%%", oxygenLevel * 100))" +
            " energy \(String(format: "%-3.2f%%", fungibleEnergyFullness * 100))" +
            " level \(String(format: "%-2.6f", fungibleEnergyContent))" +
            " cap \(String(format: "%-2.6f", fungibleEnergyCapacity))\n"
            , level: 68
        )
    }

    func absorbEnergy(_ cJoules: CGFloat) {

//        Debug.log(
//            "[Deposit " +
//            String(format: "% 6.2f ", stomach.level) +
//            String(format: "% 6.2f ", readyEnergyReserves.level) +
//            String(format: "% 6.2f ", fatReserves.level) +
//            String(format: "% 6.2f ", spawnReserves.level) +
//            String(format: "% 6.2f ", energyContent) +
//            String(format: "(% 6.2f)", cJoules),
//            level: 14
//        )

        stomach.deposit(cJoules)
        Debug.log("Deposit" + String(format: "% 6.6f joules", cJoules) + String(format: "% 6.6f%% full", 100.0 * stomach.level / stomach.capacity), level: 74)

        Debug.log(
            " Deposit " +
            String(format: "% 6.2f ", stomach.level) +
            String(format: "% 6.2f ", readyEnergyReserves.level) +
            String(format: "% 6.2f ", fatReserves.level) +
            String(format: "% 6.2f ", spawnReserves.level) +
            String(format: "% 6.2f ", energyContent) +
            String(format: "(% 6.2f)", cJoules) +
            String(format: "% 6.2f ", fungibleEnergyFullness),
            level: 74
        )
    }

    func inhale(_ howMuch: CGFloat = 1.0) {
        oxygenLevel = constrain(howMuch + oxygenLevel, lo: 0.0, hi: 1)
    }

    @discardableResult
    func withdrawFromReady(_ cJoules: CGFloat) -> CGFloat {
        return readyEnergyReserves.withdraw(cJoules)
    }

    @discardableResult
    func withdrawFromSpawn(_ cJoules: CGFloat) -> CGFloat {
        return spawnReserves.withdraw(cJoules)
    }
}
