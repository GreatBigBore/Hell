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

// Makes it easier for me to reason about splicing and slicing
typealias Segment = Genome

protocol GeneLinkable: class {
    var next: GeneLinkable? { get set }
    var prev: GeneLinkable? { get set }

    func copy() -> GeneLinkable
    func isMyself(_ thatGuy: GeneLinkable) -> Bool
}

class Genome: CustomDebugStringConvertible {
    enum Caller { case count, head, tail }

    var head: GeneLinkable? { didSet { if head == nil { reset(.head) } } }

    weak var tail: GeneLinkable?
    var count = 0

    var rcount: Int {
        var rr = 0
        for _ in makeIterator() { rr += 1 }
        return rr
    }

    var scount: Int {
        var ss = 0, cc = head
        while let curr = cc {
            ss += 1
            cc = curr.next
        }

        return ss
    }

    var isCloneOfParent = true
    var isEmpty: Bool { return count == 0 }

    var debugDescription: String {
        return makeIterator().map { return String(reflecting: $0) + "\n" }.joined()
    }

    init() {}
    init(_ gene: GeneLinkable) { asslink(gene) }
    init(_ genes: [GeneLinkable]) { genes.forEach { asslink($0) } }

    init(_ segment: Segment) { (head, tail, count) = Genome.init_(segment) }

    init(_ segments: [Segment]) { segments.forEach { asslink($0) } }

    static func init_(_ segment: Segment) -> (GeneLinkable?, GeneLinkable?, Int) {
        // Take ownership
        defer { segment.head = nil }
        return (segment.head, segment.tail, segment.count)
    }

    func releaseGenes() { head = nil }

    var resetting = false

    func reset(_ caller: Caller) {
        if resetting { return }
        resetting = true
        switch caller {
        case .count: head = nil; tail = nil
        case .head:  tail = nil; count = 0
        case .tail:  head = nil; count = 0
        }
        resetting = false
    }
}

// MARK: copy

extension Genome {
    func copy(from: Int? = nil, to: Int? = nil) -> Segment {
        return Segment(makeIterator(from: from, to: to).map { $0.copy() })
    }
}

// MARK: subscript

extension Genome {

/**
     - Attention: On complexity:

 The doc for **Collection** (not `Sequence`) says that if you can't give O(1),
 then you need to document it
 clearly. Here I am, documenting it clearly, although I've decided not to use `Collection`,
 because it's giving me runtime fits over "differing counts in successive traversals", although
 I know the count is staying the same. Anyway, `Collection` doesnt buy us enough benefit to
 make it worth the trouble to track down and fix that problem. Subscripting will be very
 slow, and I use it a lot, but I don't
 think we do enough genome-grinding for it to matter. I'll profile it, and change the code if
 it turns out I'm wrong on that.

*/
    subscript (_ ss: Int) -> GeneLinkable {
        precondition(ss < count, "Subscript \(ss) out of range 0..<\(count)")

        for (c, gene) in zip(0..., makeIterator()) {
            if c == ss {
                return gene
            }
        }
        preconditionFailure("Concession to the compiler. Shouldn't occur.")
    }
}

// MARK: Sequence - default iterator

extension Genome: Sequence {
    struct GenomeIterator: IteratorProtocol, Sequence {
        typealias Iterator = GenomeIterator
        typealias Element = GeneLinkable

        private weak var gene: GeneLinkable?
        var primed = false

        let from: Int
        let to: Int

        init(_ genome: Genome, from: Int, to: Int) {
            self.gene = genome.head
            self.from = from
            self.to = to
        }

        mutating func next() -> GeneLinkable? {
            if !primed { prime() }
            guard var curr = gene else { return nil }
            defer { gene = curr.next }
            return curr
        }

        private mutating func prime() {
            primed = true

            (0..<from).forEach { _ in
                let s = self.next()
                self.gene = nok(s)
            }
        }
    }

    func makeIterator() -> GenomeIterator {
        return makeIterator(from: 0, to: self.count)
    }

    func makeIterator(from: Int? = nil, to: Int? = nil) -> GenomeIterator {
        return GenomeIterator(self, from: from ?? 0, to: to ?? self.count)
    }
}

// MARK: Miscellaney

extension Genome {
    func dump() {
        makeIterator().forEach { print("\($0) ", terminator: "") }
        print()
    }
}