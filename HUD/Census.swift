import SpriteKit

struct Census {
    let rCurrentPopulation: Reportoid
    let rHighWaterPopulation: Reportoid
    let rHighWaterAge: Reportoid
    let ageFormatter: DateComponentsFormatter

    let rOffspring: Reportoid

    init(_ scene: GriddleScene) {
        rCurrentPopulation = scene.reportArkonia.reportoid(2)
        rHighWaterPopulation = scene.reportMisc.reportoid(2)
        rHighWaterAge = scene.reportMisc.reportoid(1)
        ageFormatter = DateComponentsFormatter()

        ageFormatter.allowedUnits = [.minute, .second]
        ageFormatter.allowsFractionalUnits = true
        ageFormatter.unitsStyle = .positional
        ageFormatter.zeroFormattingBehavior = .pad

        rOffspring = scene.reportMisc.reportoid(3)

        updateCensus()
    }

    private func updateCensus() {
        var currentTime: TimeInterval = 0
        var liveArkonsAges = [TimeInterval]()

        func partA() {
            currentTime = World.shared.getCurrentTime_()

            liveArkonsAges = GriddleScene.arkonsPortal!.children.compactMap { node in
                guard let sprite = node as? SKSpriteNode else {
                    fatalError()
                }

                guard let stepper = Stepper.getStepper(
                    from: sprite, require: false
                ) else { return nil }

                return  currentTime - stepper.birthday!
            }

            if liveArkonsAges.isEmpty { partE() } else { partB() }
        }

        func partB() {
            World.shared.getPopulation { ps in
                guard let popStats = ps else { fatalError() }

                let currentPop = popStats[0]
                let highWaterPop = popStats[1]
                let highWaterOffspring = popStats[2]

                self.rCurrentPopulation.data.text = String(currentPop)
                self.rHighWaterPopulation.data.text = String(highWaterPop)
                self.rOffspring.data.text = String(format: "%d", highWaterOffspring)
                partC()
            }
        }

        func partC() {
            World.shared.setMaxLivingAge(to: liveArkonsAges.max() ?? 0) { ageses in
                guard let ages = ageses else { fatalError() }
                let maxLivingAge = ages[0]
                let highWaterAge = ages[1]
                partD(maxLivingAge, highWaterAge)
            }
        }

        func partD(_ maxLivingAge: TimeInterval, _ highWaterAge: TimeInterval) {
            rHighWaterAge.data.text =
                ageFormatter.string(from: Double(highWaterAge))
        }

        func partE() {
            World.runAfter(deadline: DispatchTime.now() + 1) {
                let action = SKAction.run { partA() }
                GriddleScene.shared.run(action)
            }
        }

        partE()
    }
}