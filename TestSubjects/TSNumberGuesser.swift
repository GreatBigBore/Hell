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
        
        selectionControls.howManySenses = 5
        selectionControls.howManyMotorNeurons = 5
        
        return FTNumberGuesser()
    }
    
    override func makeTestSubject(parent: TSTestSubject, mutate: Bool) -> TSTestSubject? {
        return makeTestSubject(parentGenome: parent.genome, mutate: mutate)
    }
    
    override func makeTestSubject(parentGenome: Genome, mutate: Bool) -> TSTestSubject? {
        let m = Utilities.report_memory()

        var maybeMutated = parentGenome
        
        while mutate && maybeMutated == parentGenome {
            let _ = Mutator.m.setInputGenome(parentGenome).mutate()
            maybeMutated = Mutator.m.convertToGenome()
        }
        
        do{ try decoder.setInput(to: maybeMutated).decode() }
        catch { return nil }

        defer {
            let t = Utilities.report_memory()
            let mm = t - m
            print("total \(t), current \(mm)")
        }

        let brain = Translators.t.getBrain()
        return TSNumberGuesser(genome: maybeMutated, brain: brain)
    }
}

class FTNumberGuesser: FTFitnessTester {
    override func doScoringStuff(_ ts: TSTestSubject, _ outputs: [Double]) -> Double {
        guard let tg = ts as? TSNumberGuesser else { fatalError() }
        
        let guess = outputs.reduce(0.0, +)
        tg.guessedNumber = guess
        let finalScore = abs(guess - (-27.5))  // Try for -27.5
//        print("Subject \(ts.fishNumber) produced \(guess); score is \(finalScore)")
        return finalScore
    }
}
