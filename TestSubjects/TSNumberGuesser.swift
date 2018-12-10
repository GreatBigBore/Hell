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

class TSNumberGuesser: TSTestSubject {
    var guessedNumber: Double?
}

class TSNumberGuesserFactory: TestSubjectFactory {
    override func makeFitnessTester() -> FTFitnessTester {
        precondition(selectionControlsSet)
        return FTNumberGuesser()
    }

    override func makeTestSubject(parent: TSTestSubject, mutate: Bool) -> TSTestSubject? {
        precondition(selectionControlsSet)
        return makeTestSubject(parentGenome: parent.genome[...], mutate: mutate)
    }

    override func makeTestSubject(parentGenome: GenomeSlice, mutate: Bool) -> TSTestSubject? {
        precondition(selectionControlsSet)
        let mutated = super.mutate(parentGenome: parentGenome[...])

        guard decoder.setInput(to: mutated[...]).decode() else { return nil }

        let brain = Translators.t.getBrain()
        // Translators.t.reset() -- add while debugging mem; does it matter whether we reset?
        let guesser = TSNumberGuesser(genome: maybeMutated, brain: brain)
        return guesser
    }

    override func setSelectionControls() {
        selectionControls.howManySenses = 4
        selectionControls.howManyMotorNeurons = 6
        super.setSelectionControls()
    }
}

class FTNumberGuesser: FTFitnessTester {
    override func doScoringStuff(_ ts: TSTestSubject, _ outputs: [Double?]) -> Double {
        guard let tg = ts as? TSNumberGuesser else { fatalError() }

        let guess = outputs.compactMap({$0}).reduce(0.0, +)
        tg.guessedNumber = guess
        let finalScore = abs(guess - (-27.5))  // Try for -27.5
//        print("Subject \(ts.fishNumber) produced \(guess); score is \(finalScore)")
        return finalScore
    }
}
