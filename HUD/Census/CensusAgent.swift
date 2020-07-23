import Foundation

class CitizenMinder {
    weak var citizen: Stepper?
    var next: UnsafeMutablePointer<CitizenMinder>?
    var prev: UnsafeMutablePointer<CitizenMinder>?

    init(_ citizen: Stepper) { self.citizen = citizen }
}

class CensusAgent {
    var head: UnsafeMutablePointer<CitizenMinder>?
    var tail: UnsafeMutablePointer<CitizenMinder>?

    var isEmpty: Bool { head == nil }

    var ages = [Double]()
    var cOffsprings = [Double]()
    var stats = PopulationStats()

    private func checkMax(
        _ testValue: Double, _ maxValue: Double, _ arkon: Stepper
    ) -> (Double, Stepper)? {
        testValue > maxValue ? (testValue, arkon) : nil
    }

    func compress(
        _ currentTime: TimeInterval,
        _ allBirths: Int
    ) {
        var cArkons = 0
        var ageSum = TimeInterval(0), maxAge = TimeInterval(0)
        var foodHitRateSum: Double = 0, maxFoodHitRate: Double = 0
        var cOffspringSum = 0, maxCOffspring = 0

        var currentMinder = self.head

        // Citizens disappear from the roster when their steppers destruct. We
        // see this as a nil citizen in the minder. Minders stick around until
        // we see that their citizen has died, at which point we, uhh, "retire" the minder
        var oldestArkon, bestAimArkon, busiestArkon: Stepper?

        ages.removeAll(keepingCapacity: true)

        repeat {
            guard let minder = currentMinder else { break } // End of the list

            guard let arkon = minder.pointee.citizen else {
                currentMinder = delete(minder.pointee)
                continue
            }

            let age = currentTime - arkon.fishday.birthday
            ageSum += age
            ages.append(age)

            if let (newMax, newArkon) = checkMax(
                age, maxAge, minder.pointee.citizen!
            ) { maxAge = newMax; oldestArkon = newArkon }

            let foodHitRate = arkon.cJumps == 0 ? 0 : Double(arkon.cFoodHits) / Double(arkon.cJumps)
            foodHitRateSum += foodHitRate

            if let (newMax, newArkon) = checkMax(
                foodHitRate, maxFoodHitRate, minder.pointee.citizen!
            ) { maxFoodHitRate = newMax; bestAimArkon = newArkon }

            if let (newMax, newArkon) = checkMax(
                Double(arkon.cOffspring), Double(maxCOffspring), minder.pointee.citizen!
            ) { maxCOffspring = Int(newMax); busiestArkon = newArkon }

            cOffspringSum += arkon.cOffspring
            cOffsprings.append(Double(arkon.cOffspring))

            cArkons += 1

            currentMinder = currentMinder!.pointee.next
        } while currentMinder != nil

        self.stats.update(
            averageAge: (cArkons == 0) ? 0 : (Double(ageSum) / Double(cArkons)),
            maxAge: Double(maxAge), medAge: getMedianAge(),
            averageFoodHitRate:(cArkons == 0) ? 0 : (foodHitRateSum / Double(cArkons)),
            maxFoodHitRate: maxFoodHitRate,
            averageCOffspring:(cArkons == 0) ? 0 : (Double(cOffspringSum) / Double(cArkons)),
            medCOffspring: getMedianCOffspring(), maxCOffspring: Double(maxCOffspring), allBirths: allBirths,
            currentPopulation: cArkons, oldestArkon: oldestArkon, bestAimArkon: bestAimArkon,
            busiestArkon: busiestArkon
        )
    }

    // Clients don't need to delete nodes. We keep weak refs, so when the
    // arkon goes away, we drop it off the list automatically
    private func delete(_ node: CitizenMinder) -> UnsafeMutablePointer<CitizenMinder>? {
        guard let head = self.head, let tail = self.tail else { fatalError() }

        // Note: identity, not just equality, although I imagine equality would be fine
        if head.pointee === node && tail.pointee === node {
            // Deleting the only remaining node on the list
            self.head = nil
            self.tail = nil
            return nil

        } else if head.pointee === node { // Deleting first node

            self.head = node.next
            node.next!.pointee.prev = nil // we know there's a next bc the tail is non-nil
            return node.next

        } else if tail.pointee === node { // Deleting last node

            self.tail = node.prev
            node.prev!.pointee.next = nil
            return nil

        } else { // Deleting somewheres in the middle

            node.prev!.pointee.next = node.next
            node.next!.pointee.prev = node.prev
            return node.next
        }
    }

    private func getMedianAge() -> TimeInterval {
        if self.ages.isEmpty { return 0 }

        let m = self.ages.sorted()
        let ss = m.count / 2

        if (m.count % 2) == 0 {
            return m[ss]
        } else {
            return (m[ss] + m[ss + 1]) / 2
        }
    }

    private func getMedianCOffspring() -> TimeInterval {
        if self.cOffsprings.isEmpty { return 0 }

        let m = self.cOffsprings.sorted()
        let ss = m.count / 2

        if (m.count % 2) == 0 {
            return m[ss]
        } else {
            return (m[ss] + m[ss + 1]) / 2
        }
    }

    // Always insert at the front; we don't care about order or nuthin
    func insert(_ stepper: Stepper) {
        if head == nil {
            head = UnsafeMutablePointer<CitizenMinder>.allocate(capacity: 1)
            head!.initialize(to: CitizenMinder(stepper))

            tail = head
        } else {
            head!.pointee.prev = UnsafeMutablePointer<CitizenMinder>.allocate(capacity: 1)
            head!.pointee.prev!.initialize(to: CitizenMinder(stepper))

            head!.pointee.prev!.pointee.next = head
            head = head!.pointee.prev
        }
    }
}
