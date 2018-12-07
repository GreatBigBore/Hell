//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//

import Foundation

extension Foundation.Notification.Name {
    static let select = Foundation.Notification.Name("select")
    static let selectComplete = Foundation.Notification.Name("selectComplete")
    static let setSelectionParameters = Foundation.Notification.Name("setSelectionParameters")
}

class Selector {
    private var fitnessTester: FTFitnessTester!
    private let notificationCenter = NotificationCenter.default
    private let semaphore: DispatchSemaphore
    weak public  var stud: TSTestSubject?
    private var tsFactory: TestSubjectFactory
    private var selectorWorkItem: DispatchWorkItem!
    private var thisGenerationNumber = 0
    private var observerHandle: NSObjectProtocol?
    private var compareFunctionOperator = CompareFunctionOperator.BE

    init(tsFactory: TestSubjectFactory, semaphore: DispatchSemaphore) {
        self.tsFactory = tsFactory
        self.fitnessTester = tsFactory.makeFitnessTester()
        self.semaphore = semaphore
        self.tsFactory = tsFactory

        let n = Foundation.Notification.Name.setSelectionParameters
        
        observerHandle = notificationCenter.addObserver(forName: n, object: nil, queue: nil) {
            [unowned self] n in self.setSelectionParameters(n)
        }
    }

    deinit {
        print("Selector deinit")
        selectorWorkItem = nil
        if let ohMy = observerHandle { notificationCenter.removeObserver(ohMy) }
    }

    func cancel() { semaphore.signal(); selectorWorkItem.cancel(); }
    var isCanceled: Bool { return selectorWorkItem.isCancelled }

    private func rLoop() {
        while true {
            if selectorWorkItem.isCancelled { print("rLoop detects cancel"); break }

            semaphore.wait()
            let newSurvivors = select(against: self.stud!)
            let selectionResults = [NotificationType.selectComplete : newSurvivors]
            let n = Foundation.Notification.Name.selectComplete

            notificationCenter.post(name: n, object: self, userInfo: selectionResults as [AnyHashable : Any])

            semaphore.signal()  // Give control back to the main thread
        }
    }

    public func scoreAboriginal(_ aboriginal: TSTestSubject) {
        guard let score = fitnessTester.administerTest(to: aboriginal)
            else { fatalError() }

        aboriginal.fitnessScore = score
    }

    private func select(against stud: TSTestSubject) -> [TSTestSubject]? {
        thisGenerationNumber += 1

        var bestScore = stud.fitnessScore
        var stemTheFlood = [TSTestSubject]()

        for _ in 0..<selectionControls.howManySubjectsPerGeneration {
            guard let ts = tsFactory.makeTestSubject(parent: stud, mutate: true)
                else { continue }

            if selectorWorkItem.isCancelled { break }
            if ts.genome == stud.genome { continue }

            guard let score = fitnessTester.administerTest(to: ts)
                else { continue }

            ts.debugMarker = 424242

//            ts.fitnessScore = score
            if score > bestScore! { continue }

            if compareFunctionOperator == .BE {
                if score <= bestScore! { bestScore = score }
                else { continue }
            } else {
                if score < bestScore! { bestScore = score }
                else { continue }
            }

            // Start getting rid of the less promising candidates
            if stemTheFlood.count >= selectionControls.maxKeepersPerGeneration {
                _ = stemTheFlood.popBack()
            }

            stemTheFlood.append(ts)
        }

        if stemTheFlood.isEmpty { /*print("No survivors in \(thisGenerationNumber)");*/ return nil }
        return stemTheFlood
    }

    var comparisonMode = Archive.Comparison.BE

    @objc private func setSelectionParameters(_ notification: Notification) {
        guard let u = notification.userInfo,
            let p = u[NotificationType.select] as? TSTestSubject,
            let e = u["comparisonMode"] else { preconditionFailure() }

        self.stud = p

        guard let c = e as? Archive.Comparison else { preconditionFailure() }
        comparisonMode = c
    }

    public func startThread() {

        self.selectorWorkItem = DispatchWorkItem { [weak self] in self!.rLoop()
            self!.selectorWorkItem = nil
        }

        DispatchQueue.global(qos: .background).async(execute: selectorWorkItem)
    }

}
