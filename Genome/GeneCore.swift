import Foundation

enum GeneCore {
    case activator(_ functionName: AFn.FunctionName, _ isMutatedCopy: Bool)
    case double(_ rawValue: Double, _ isMutatedCopy: Bool)
    case empty
    case int(_ rawValue: Int, _ range: Int, _ isMutatedCopy: Bool)
    case upConnector(_ upConnector: UpConnector, _ isMutatedCopy: Bool)

    static var cLiveGenes = 0 { willSet {
        if GeneCore.cLiveGenes > GeneCore.highWaterMark{
            GeneCore.highWaterMark = GeneCore.cLiveGenes
        }
        }}

    static var highWaterMark = 0

    static let downConnectorTopOfRange = 1000
    static let hoxTopOfRange = 10
    static let lockTopOfRange = 10
    static let upConnectorChannelTopOfRange = 1000

    static func getWeightedRandomGene() -> GeneType {
        let weightMap: [GeneType : Int] = [
            .activator: 7, .bias: 7, .downConnector: 15, .hox: 0, .lock: 0, .layer: 5,
            .neuron: 20/*, .policy: 1, .skipAnyType: 1, .skipOneType: 1*/, .upConnector: 15
        ]

        let weightRange = weightMap.reduce(0, { return $0 + $1.value })
        let randomValue = Int.random(in: 0..<weightRange)

        var runningTotal = 0
        for (key, value) in weightMap {
            runningTotal += value
            if runningTotal > randomValue { return key }
        }

        fatalError()
    }

    static func makeRandomGene() -> GeneProtocol {
        let geneType = getWeightedRandomGene()

        switch geneType {
        case .activator:     return gActivatorFunction.makeRandomGene()
        case .bias:          return gBias.makeRandomGene()
            //        case .downConnector: return gDownConnector.makeRandomGene()
            //        case .hox:           return gHox.makeRandomGene()
            //        case .lock:          return gLock.makeRandomGene()
            //        case .layer:         return gLayer.makeRandomGene()
            //        case .neuron:        return gNeuron.makeRandomGene()
            //        case .policy:        return gPolicy.makeRandomGene()
            //        case .skipAnyType:   return gSkipAnyType.makeRandomGene()
        //        case .skipOneType:   return gSkipOneType.makeRandomGene()
        case .upConnector:   return gUpConnector.makeRandomGene()
        default: preconditionFailure()
        }
    }

    static func mutated(from gene: GeneProtocol) -> GeneProtocol {
        switch gene {
        case is gActivatorFunction:     return gActivatorFunction.makeRandomGene()
        case is gBias:          return gBias.makeRandomGene()
        case is gDownConnector: return gDownConnector.makeRandomGene()
        case is gHox:           return gHox.makeRandomGene()
        case is gLock:          return gLock.makeRandomGene()
        case is gLayer:         return gLayer.makeRandomGene()
        case is gNeuron:        return gNeuron.makeRandomGene()
            //        case .policy:        return gPolicy.makeRandomGene()
            //        case .skipAnyType:   return gSkipAnyType.makeRandomGene()
        //        case .skipOneType:   return gSkipOneType.makeRandomGene()
        case is gUpConnector:   return gUpConnector.makeRandomGene()
        default: preconditionFailure()
        }
    }

    static func mutated(from geneCore: GeneCore) -> GeneCore {
        switch geneCore {
        case let .double(currentRawValue, _):
            let newRawValue = geneCore.mutated(from: currentRawValue)
            return GeneCore.double(newRawValue, newRawValue != currentRawValue)

        case let .int(currentRawValue, topOfRange, _):
            let newRawValue = geneCore.mutated(from: currentRawValue, topOfRange: topOfRange)
            return GeneCore.int(newRawValue, topOfRange, newRawValue != currentRawValue)

        case let .activator(currentFunctionName, _):
            let newFunctionName = AFn.FunctionName.allCases.randomElement()!
            return GeneCore.activator(newFunctionName, newFunctionName != currentFunctionName)

        case let .upConnector(currentUpConnector, _):
            let newAmplifier = geneCore.mutated(from: currentUpConnector.amplifier)

            let newChannel_ = geneCore.mutated(
                from: currentUpConnector.channel.channel,
                topOfRange: currentUpConnector.channel.topOfRange
            )

            let newChannel = UpConnectorChannel(
                channel: newChannel_, topOfRange: GeneCore.upConnectorChannelTopOfRange
            )

            let newWeight_ = geneCore.mutated(from: currentUpConnector.weight.weight)
            let newWeight = UpConnectorWeight(weight: newWeight_)

            let isMutatedCopy =
                newChannel != currentUpConnector.channel ||
                    newWeight != currentUpConnector.weight ||
                    newAmplifier != currentUpConnector.amplifier

            let newUpConnector = UpConnector(newChannel, newWeight, newAmplifier)
            return GeneCore.upConnector(newUpConnector, isMutatedCopy)

        default: preconditionFailure()
        }
    }

    fileprivate func mutated(from currentValue: Double) -> Double {
        // 75% of the time, you get a copy
        if Double.random(in: 0..<1) < 0.75 {
            return currentValue
        }

        return Double.random(in: 0..<1)
    }

    fileprivate func mutated(from currentValue: Int, topOfRange: Int) -> Int {
        // 75% of the time, you get a copy
        if Double.random(in: 0..<1) < 0.75 { return currentValue }

        return Int.random(in: 0..<topOfRange)
    }

    fileprivate func mutated(from currentChannel: UpConnectorChannel) -> UpConnectorChannel {
        // 75% of the time, you get a copy
        if Double.random(in: 0..<1) < 0.75 { return currentChannel }

        let mutateChannel = Bool.random()
        let newChannel = mutateChannel ?
            mutated(from: currentChannel.channel, topOfRange: currentChannel.topOfRange) :
            currentChannel.channel

        return UpConnectorChannel(channel: newChannel, topOfRange: currentChannel.topOfRange)
    }

    fileprivate func mutated(from currentAmplifier: UpConnectorAmplifier) -> UpConnectorAmplifier {
        // 75% of the time, you get a copy
        if Double.random(in: 0..<1) < 0.75 { return currentAmplifier }

        let mutateAmplifier = Bool.random()
        let newMultiplier = mutateAmplifier ?
            mutated(from: currentAmplifier.multiplier) : currentAmplifier.multiplier

        let newMode = mutateAmplifier ?
            UpConnectorAmplifier.AmplificationMode.allCases.randomElement()! :
            currentAmplifier.amplificationMode

        return UpConnectorAmplifier(amplificationMode: newMode, multiplier: newMultiplier)
    }

    fileprivate func mutated(from upConnector: UpConnector) -> UpConnector {
        let mutatedChannel_ = mutated(
            from: upConnector.channel.channel, topOfRange: upConnector.channel.topOfRange
        )

        let mutatedChannel =
            UpConnectorChannel(channel: mutatedChannel_, topOfRange: upConnector.channel.topOfRange)

        let mutatedWeight_ = mutated(from: upConnector.weight.weight)
        let mutatedWeight = UpConnectorWeight(weight: mutatedWeight_)
        let mutatedAmplifier = mutated(from: upConnector.amplifier)

        return UpConnector(mutatedChannel, mutatedWeight, mutatedAmplifier)
    }

    fileprivate func mutated(from functionName: AFn.FunctionName) -> AFn.FunctionName {
        // 75% of the time, you get a copy
        if Double.random(in: 0..<1) < 0.75 { return functionName }

        guard let newFunctionName = AFn.FunctionName.allCases.randomElement() else {
            preconditionFailure()
        }

        return newFunctionName
    }
}