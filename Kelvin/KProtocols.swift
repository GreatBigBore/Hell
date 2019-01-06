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
#if SIGNAL_GRID_DIAGNOSTICS
import Foundation

protocol KIdentifiable: CustomStringConvertible {
    var id: KIdentifier { get }
}

protocol KIdentifierProtocol: CustomStringConvertible {
    var description: String { get }
    var familyID: [Int] { get }
    var myID: Int { get }

    init(_ type: String, _ familyID: [Int], _ myID: Int)
}

protocol KInputProtocol {
    var inputRelays: [KSignalRelay] { get set }
}

protocol KOutputProtocol {
    var output: Double { get }
}

protocol KRelayProtocol: class, KInputProtocol, KOutputProtocol {
    var breaker: KSignalRelay? { get set }
    var isOperational: Bool { get }
}
#endif