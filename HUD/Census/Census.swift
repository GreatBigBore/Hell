import SpriteKit

struct Fishday {
    private static var TheFishNumber = 0

    let birthday: TimeInterval
    let cNeurons: Int
    let fishNumber: Int
    let name: ArkonName

    // All this needs to happen on a serial queue. The Census serial
    // queue seems like the most sensible one, given that it's census-related
    init(currentTime: Int, cNeurons: Int) {
        self.cNeurons = cNeurons
        self.fishNumber = Fishday.getNextFishNumber()
        self.name = ArkonName.makeName()
        self.birthday = TimeInterval(currentTime)
    }

    private static func getNextFishNumber() -> Int {
        defer { Fishday.TheFishNumber += 1 }
        return Fishday.TheFishNumber
    }
}

class Census {
    static var shared = Census()

    let censusAgent = CensusAgent()
    let lineChartData = LineChartData(6)

    private(set) var allBirths = 0
    private(set) var cLiveNeurons = 0
    private(set) var highwaterAge: TimeInterval = 0
    private(set) var highwaterPopulation = 0
    private(set) var highwaterFoodHitrate = 0.0
    var populated = false

    // Markers for said arkons, not the arkons themselves
    var oldestLivingMarker, aimestLivingMarker, busiestLivingMarker: SKSpriteNode?

    var tickTimer: Timer!

    static let dispatchQueue = DispatchQueue(
        label: "ak.census.q",
        target: DispatchQueue.global()
    )

    init() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Census.dispatchQueue.async { self.updateReports() }
        }
    }

    func reSeedWorld() { populated = false }
}

extension Census {
    static func getAge(of arkon: Stepper, at currentTime: Int) -> TimeInterval {
        return TimeInterval(currentTime) - arkon.fishday.birthday
    }
}

extension Census {
    func updateReports(_ worldClock: Int) {
        censusAgent.compress(
            TimeInterval(worldClock), self.allBirths
        )

        markExemplars()

        highwaterAge = TimeInterval(max(censusAgent.stats.maxAge, highwaterAge))
        highwaterFoodHitrate = max(censusAgent.stats.maxFoodHitRate, highwaterFoodHitrate)
        highwaterPopulation = max(censusAgent.stats.currentPopulation, highwaterPopulation)

        lineChartData.update([
            censusAgent.stats.averageAge, censusAgent.stats.maxAge,
            censusAgent.stats.medAge, 0, 0, Double(highwaterAge)
        ])
    }
}

private extension Census {
    func markExemplars() {
        zip(
            [censusAgent.stats.oldestArkon, censusAgent.stats.bestAimArkon, censusAgent.stats.busiestArkon],
            [oldestLivingMarker, aimestLivingMarker, busiestLivingMarker]
        ).forEach {
            (a, m) in
            guard let arkon = a, let marker = m else { return }
            updateMarker(marker, arkon.thorax)
        }
    }

    func updateMarker(_ marker: SKSpriteNode, _ markCandidate: SKSpriteNode) {
        if marker.parent != nil { marker.removeFromParent() }
        markCandidate.addChild(marker)
    }
}

extension Census {
    func registerBirth(_ myNetStructure: NetStructure, _ myParent: Stepper?) -> Int {
        myParent?.censusData.increment(.offspring)

        self.cLiveNeurons += myNetStructure.cNeurons
        self.allBirths += 1

        return myNetStructure.cNeurons
    }
}
