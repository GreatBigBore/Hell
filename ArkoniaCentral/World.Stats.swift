import CoreGraphics

protocol StatsProtocol {
    var currentPopulation: Int { get }
    var currentTime: Int { get }
    var entropy: CGFloat { get }
    var highWaterPopulation: Int { get }
    var maxCOffspringForLiving: Int { get }
    var maxLivingAge: Int { get }
    var highWaterAge: Int { get }
    var highWaterCOffspring: Int { get }
}

extension World {
    static let stats = Stats()

    struct StatsCopy: StatsProtocol {
        let currentPopulation: Int
        let currentTime: Int
        let entropy: CGFloat
        let highWaterPopulation: Int
        let maxCOffspringForLiving: Int
        let maxLivingAge: Int
        let highWaterAge: Int
        let highWaterCOffspring: Int
    }

    class Stats: StatsProtocol {
        private var TheFishNumber = 0

        private(set) var currentPopulation = 0
        private(set) var currentTime = 0
        var entropy: CGFloat { 1 - (CGFloat(currentTime) / 100) }
        private(set) var highWaterPopulation = 0
        private(set) var maxCOffspringForLiving = 0
        private(set) var maxLivingAge = 0
        private(set) var highWaterAge = 0
        private(set) var highWaterCOffspring = 0

        var gameAge: Int { return currentTime }

        var wiGetStats: DispatchWorkItem?

        init() { updateWorldClock() }

        func copy() -> StatsCopy {
            return StatsCopy(
                currentPopulation: self.currentPopulation,
                currentTime: self.currentTime,
                entropy: self.entropy,
                highWaterPopulation: self.highWaterPopulation,
                maxCOffspringForLiving: self.maxCOffspringForLiving,
                maxLivingAge: self.maxLivingAge,
                highWaterAge: self.highWaterAge,
                highWaterCOffspring: self.highWaterCOffspring
            )
        }
    }
}

extension World.Stats {
    typealias OCGetStats = (World.StatsCopy) -> Void

    func decrementPopulation(_ birthdayOfDeceased: Int) {
        Grid.shared.serialQueue.async { [unowned self] in
            let ageOfDeceased = self.currentTime - birthdayOfDeceased
            self.highWaterAge = max(self.highWaterAge, ageOfDeceased)
            self.currentPopulation -= 1
        }
    }

    func getNextFishNumber(_ onComplete: @escaping (Int) -> Void) {
        Grid.shared.serialQueue.async {
            let next = self.getNextFishNumber_()
            onComplete(next)
        }
    }

    func getNextFishNumber_() -> Int {
        defer { World.stats.TheFishNumber += 1 }
        return World.stats.TheFishNumber
    }

    func getStats(_ onComplete: @escaping OCGetStats) {
        wiGetStats = DispatchWorkItem { [unowned self] in self.getStats_(onComplete) }
        Grid.shared.serialQueue.async(execute: wiGetStats!)
    }

    func getStats_(_ onComplete: @escaping OCGetStats) { onComplete(self.copy()) }

    func getTimeSince(_ time: Int, _ onComplete: @escaping (Int) -> Void) {
        Grid.shared.serialQueue.async(flags: .barrier) { [unowned self] in
            onComplete(self.currentTime - time)
        }
    }

    func registerAge(_ age: Int, _ onComplete: @escaping OCGetStats) {
        Grid.shared.serialQueue.async(flags: .barrier) { [unowned self] in
            self.maxLivingAge = max(age, self.maxLivingAge)
            self.highWaterAge = max(self.maxLivingAge, self.highWaterAge)
            onComplete(self.copy())
        }
    }

    func registerBirth(myParent: Stepper?, meOffspring: SpawnProtocol) {
        Grid.shared.serialQueue.async { [unowned self] in
            self.registerBirth_(myParent, meOffspring)
        }
    }

    func registerBirth_(_ myParent: Stepper?, _ meOffspring: SpawnProtocol) {
        self.currentPopulation += 1
        self.highWaterPopulation = max(self.highWaterPopulation, self.currentPopulation)

        myParent?.cOffspring += 1

        meOffspring.fishNumber = self.TheFishNumber
        self.TheFishNumber += 1

        meOffspring.birthday = self.currentTime

        self.maxCOffspringForLiving = max(
            (myParent?.cOffspring ?? 0), self.maxCOffspringForLiving
        )

        self.highWaterCOffspring = max(
            self.maxCOffspringForLiving, self.highWaterCOffspring
        )

        Log.L.write("nil? \(myParent == nil), pop \(self.currentPopulation), cOffspring \(myParent?.cOffspring ?? -1)" +
            " hw cOffspring \(self.maxCOffspringForLiving), real hw cOfspring \(self.highWaterCOffspring)", level: 37)
    }

    private func updateWorldClock() {
        Grid.shared.serialQueue.async { [unowned self] in
            self.currentTime += 1

            Grid.shared.serialQueue.asyncAfter(deadline: DispatchTime.now() + 1) {
                [unowned self] in self.updateWorldClock()
            }
        }
    }

}
