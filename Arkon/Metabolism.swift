import SpriteKit

enum EnergyReserveType: CaseIterable {
    case bone, fatReserves, readyEnergyReserves, spawnReserves, stomach
}

class EnergyReserve {
    static let startingLevelBone: CGFloat = 100
    static let startingLevelFat: CGFloat = 300
    static let startingLevelReadyEnergy: CGFloat = 300
    static let spawnReservesCapacity: CGFloat = 3200

    static let startingEnergyLevel = (
        startingLevelBone + startingLevelFat + startingLevelReadyEnergy
    )

    var isAmple: Bool { return level >= overflowThreshold }
    var isEmpty: Bool { return level <= 0 }
    var isFull: Bool { return level >= capacity }
    var mass: CGFloat { return level / energyDensity }

    let capacity: CGFloat                       // in mJ
    let energyDensity: CGFloat                  // in J/g
    let energyReserveType: EnergyReserveType
    let overflowThreshold: CGFloat              // in mJ

    var level: CGFloat = 0                      // in mJ
    let name: String

    init(_ type: EnergyReserveType) {
        self.energyReserveType = type

        let level: CGFloat

        switch type {
        case .bone:
            name = "bone"
            capacity = 100
            energyDensity = 1
            level = EnergyReserve.startingLevelBone
            overflowThreshold = CGFloat.infinity

        case .fatReserves:
            name = "fatReserves"
            capacity = 3200
            energyDensity = 8
            level = EnergyReserve.startingLevelFat
            overflowThreshold = 1600

        case .readyEnergyReserves:
            name = "readyEnergyReserves"
            capacity = 2400
            energyDensity = 4
            level = EnergyReserve.startingLevelReadyEnergy
            overflowThreshold = 1000

        case .spawnReserves:
            name = "spawnReserves"
            capacity = 3200
            energyDensity = 16
            level = 0
            overflowThreshold = CGFloat.infinity

        case .stomach:
            name = "stomach"
            capacity = 800
            energyDensity = 2
            level = 0
            overflowThreshold = 0
        }

        self.level = level
    }

    func deposit(_ cJoules: CGFloat) {
        if cJoules <= 0 { return }  // Energy level can go slightly neg, rounding?

        let js = String(format: "%3.3f", cJoules)
        let Ls = String(format: "%3.3f", level)
        let fs = String(format: "%3.3f", level / capacity)
        Debug.log("deposit \(js) to \(name), level = \(Ls), fullness = \(fs)", level: 74)
        level = min(level + cJoules, capacity)
    }

    @discardableResult
    func withdraw(_ cJoules: CGFloat) -> CGFloat {
        if cJoules == 0 { return 0 }
        precondition(cJoules > 0)

        assert(cJoules < CGFloat.infinity)

        let net = min(level, cJoules)
        level -= net

        let js = String(format: "%3.3f", cJoules)
        let Ls = String(format: "%3.3f", level)
        let fs = String(format: "%3.3f", level / capacity)
        let ns = String(format: "%3.3f", net)
        Debug.log("withdraw \(js)(\(ns)) from \(name), level = \(Ls), fullness = \(fs)", level: 74)
        return net
    }
}

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
