import CoreGraphics

// swiftlint:disable function_body_length

extension Plotter {
    static let cMotorGridlets = Arkonia.cMotorGridlets
    static var cNaN = 0
    static var cInf = 0

    func setRoute(
        _ senseData: [Double], _ senseGrid: CellSenseGrid, _ onComplete: @escaping (CellShuttle) -> Void
    ) {
        guard let ch = scratch else { fatalError() }
        guard let st = ch.stepper else { fatalError() }
        guard let net = st.net else { fatalError() }

        Debug.log(level: 119) { "makeCellShuttle for \(six(st.name)) from \(st.gridCell!)" }
        Debug.log(level: 122) { "senseData \(senseData)" }

        var motorOutputs = [(Int, Double)]()

        func a() {
            net.getMotorOutputs(senseData) { rawOutputs in
                Debug.log(level: 145) { "rawOutputs \(rawOutputs)" }

                motorOutputs = zip(0..., rawOutputs).compactMap { position, rawOutput in
                    if rawOutput.isNaN {
                        Plotter.cNaN += 1
                        Debug.log { "NaN \(Plotter.cNaN)" }
                        return nil
                    }

                    if rawOutput.isInfinite {
                        Plotter.cInf += 1
                        Debug.log { "cInf \(Plotter.cInf)" }
                        return nil
                    }

                    return (position, rawOutput)
                }

                b()
            }
        }

        func b() {
            let motorOutput_ = motorOutputs[0].1

            // Divide the circle into cMotorGridlets + 1 slices
            let s0 = motorOutput_
            let s1 = s0 * Double(Plotter.cMotorGridlets + 1)
            let s2 = floor(s1)
            let s3 = Int(s2)
            let motorOutput = s3
            Debug.log(level: 150) { "motorOutput \(motorOutputs) -> \(motorOutput)" }

            var skip = 0
            let gridlets: [Int] = (0..<(Plotter.cMotorGridlets + 1)).map { wrappingIndex in
                if wrappingIndex == 0 { return motorOutput }

                let wrapped = wrappingIndex % (Plotter.cMotorGridlets + 1)

                if wrapped == motorOutput { skip = 1 }

                return (wrappingIndex + skip) % (Plotter.cMotorGridlets + 1)
            }

            var targetOffset: Int = 0
            if let toff = gridlets.first(where: {
                senseGrid.cells[$0] is HotKey && (senseGrid.cells[$0].contents != .arkon || $0 == 0)
            }) { targetOffset = toff }

            Debug.log(level: 139) { "toff \(targetOffset) from gridlets \(gridlets)" }

            let fromCell: HotKey?
            let toCell: HotKey

            if targetOffset == 0 {
                guard let t = senseGrid.cells[targetOffset] as? HotKey else { fatalError() }

                toCell = t; fromCell = nil
                Debug.log(level: 104) { "toCell at \(t.gridPosition) holds \(six(t.sprite?.name))" }
            } else {
                guard let t = senseGrid.cells[targetOffset] as? HotKey else { fatalError() }
                guard let f = senseGrid.cells[0] as? HotKey else { fatalError() }

                toCell = t; fromCell = f
                Debug.log(level: 104) {
                    let m = senseGrid.cells.map { "\($0.gridPosition) \(type(of: $0)) \($0.contents)" }

                    return "I am \(six(st.name))" +
                    "; toCell at \(t.gridPosition) holds \(six(t.sprite?.name))" +
                    ", fromCell at \(f.gridPosition) holds \(six(f.sprite?.name))\n" +
                    "senseGrid(\(m)"
                }

                assert(fromCell?.contents ?? .nothing == .arkon)
            }

            Debug.log(level: 98) { "targetOffset: \(targetOffset)" }

            assert((fromCell?.contents ?? .arkon) == .arkon)
            onComplete(CellShuttle(fromCell, toCell))
        }

        a()
    }
}
