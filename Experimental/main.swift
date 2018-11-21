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

class TestBreeder {
    var newGenome: Genome!
    var shouldKeepRunning = true
    var theTestSubjects: Breeder.Generation!

    var currentGenerationNumber = 0
    func select() {
        let bestFitnessScore = Breeder.bb.breedAndSelect()

        currentGenerationNumber += 1
        if currentGenerationNumber >= Breeder.howManyGenerations || bestFitnessScore == 0 {
            self.shouldKeepRunning = false
        }
    }
}

var newGenome = Genome()

newGenome += "L."
for _ in 0..<10 {
    newGenome += "N.A(true).W(1).b(0).t(10000)."
}

Breeder.howManyGenerations = 500
Breeder.howManyTestSubjectsPerGeneration = 500

let testSubjectFactory = TSNumberGuesser.TSF()
_ = Breeder.bb.setTestSubjectFactory(testSubjectFactory)
Breeder.bb.setFitnessTester(FTNumberGuesser())
let tb = TestBreeder()

let v = RepeatingTimer(timeInterval: 0.1)
v.eventHandler = {
    tb.select()
}
v.resume()
while tb.shouldKeepRunning {  }
//print(Breeder.bb.getBestGenome())
