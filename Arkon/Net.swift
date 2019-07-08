import Surge

class Net {

    let biases: [Double]
    let cBiases: Int
    let cWeights: Int
    let layers: [Int]
    let weights: [Double]

    init(parentBiases: [Double]?, parentWeights: [Double]?, layers: [Int]?) {

        if let L = layers { self.layers = Net.mutateStructure(L) }
        else { self.layers = Arkon.layers! }

        (cWeights, cBiases) = Net.computeParameters(self.layers)

        self.biases = Net.mutateNetStrand(parentStrand: parentBiases, targetLength: cBiases)
        self.weights = Net.mutateNetStrand(parentStrand: parentWeights, targetLength: cWeights)

//        print("L", self.layers, self.layers.count, "b", cBiases, self.biases.count, "w", cWeights, self.weights.count)
    }

    static func computeParameters(_ layers: [Int]) -> (Int, Int) {
        var cWeights = 0
        for c in 0..<(layers.count - 1) {
            cWeights += layers[c] * layers[c + 1]
        }

        var cBiases = 0
        for b in 1..<layers.count {
            cBiases += layers[b]
        }

        return (cWeights, cBiases)
    }

    func getMotorOutputs(_ sensoryInputs: [Double]) -> [Double] {
        assert(sensoryInputs.count == ArkoniaCentral.cSenseNeurons)

        var ncSS = 0
        var a0 = Matrix<Double>(sensoryInputs.map { [$0] })

        for _ in 0..<layers.count - 1 {
            defer { ncSS += 1 }
            let nc0 = layers[ncSS + 0]
            let nc1 = layers[ncSS + 1]

            let W = Matrix<Double>((0..<nc1).map { col in
                (0..<nc0).map { row in self.weights[col * nc0 + row] }
            })

            let b = Matrix<Double>((0..<nc1).map { [self.biases[$0]] })

//            let b = Matrix<Double>((0..<nc1).map { _ in [Double.random(in: -1.0..<1.0)] })

            let t2 = Surge.mul(W, a0)
            let t3 = Surge.add(t2, b)
            let t4 = t3.joined()
//            a0 = Matrix<Double>(t4.map { [AFn.function[AFn.FunctionName.sigmoid]!($0)] })
            a0 = Matrix<Double>(t4.map { [sin($0)] })
        }

//        print("mo", (0..<a0.rows).map { a0[$0, 0] })
        return (0..<a0.rows).map { a0[$0, 0] }
    }

    static func mutateNetStrand(parentStrand: [Double]?, targetLength: Int) -> [Double] {
        var dd: [Double]?
        if let d = parentStrand { dd = World.mutator.mutateRandomDoubles(d) }
        if dd == nil { dd = (0..<targetLength).map { _ in Double.random(in: -1..<1) } }
        else {
            if dd!.count > parentStrand!.count {
                dd!.append(contentsOf:
                    (parentStrand!.count..<dd!.count).map { _ in Double.random(in: -1..<1) }
                )
            }
        }

//        print("mns", parentStrand ?? [], targetLength)
        return dd!
    }

    static func mutateStructure(_ layers: [Int]) -> [Int] {

        if layers.count <= 3 { return layers }

        var mutated = [ArkoniaCentral.cSenseNeurons]

        for L in 1..<(layers.count - 2) {
            let r = Int.random(in: -10..<10)
            if r == 0 {
                let s = Int.random(in: -10..<10)
                if s > 8 { continue }
                else if s < -9 {
                    let t = Int.random(in: -10..<10)
                    mutated.append(abs(t))
                }

                mutated.append(abs(L))
            } else {
                mutated.append(abs(r))
            }
        }

        mutated.append(ArkoniaCentral.cMotorNeurons)

        return mutated
    }

    static func randomWithGap() -> Double {
        let firstDouble = Double.random(in: -1..<1)
        let sign: Double = firstDouble >= 0 ? 1 : -1
        return firstDouble + (abs(firstDouble) < 0.5 ? (0.5 * sign) : 0)
    }

}
