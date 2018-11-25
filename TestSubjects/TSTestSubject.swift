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

class TSTestSubject {
    static var theFishNumber = 0
    
    private(set) var myFishNumber: Int
    private(set) var brain: BrainStem?
    private(set) var genome: Genome
    private let fitnessTester: TestSubjectFitnessTester
    
    init(with genome: Genome, brain: BrainStem? = nil, fitnessTester: TestSubjectFitnessTester) {
        self.brain = brain
        self.genome = genome
        self.fitnessTester = fitnessTester
        self.myFishNumber = TSTestSubject.theFishNumber
        TSTestSubject.theFishNumber += 1
    }
    
    func getFitnessScore() -> Double? {
        guard let b = self.brain else { preconditionFailure("No brain, no score.") }
        return b.fitnessScore
    }
    
    func setBrain(_ brain: BrainStem) { self.brain = brain }
    
    func setFitnessScore(_ score: Double) { self.brain!.fitnessScore = score }
    
    func submitToTest(for sensoryInput: [Double]) -> [Double]? {
        let testOutputs = fitnessTester.administerTest(to: self, for: sensoryInput)
        let _ = fitnessTester.setFitnessScore(for: self, outputs: testOutputs)
        return testOutputs
    }
}
