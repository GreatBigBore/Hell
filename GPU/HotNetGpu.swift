import MetalPerformanceShaders

typealias Number = Float32

let NumberSize = MemoryLayout<Number>.size
let NumberTypeInGPU = MPSDataType.float32

final class HotNetGpu: HotNet {
    let commandQueue: MTLCommandQueue
    let device = GPUArray.shared.next()
    var hotLayers = [HotLayerGpu]()
    var neuronsInMatrix: MPSMatrix!
    var neuronsOutMatrix: MPSMatrix!
    let topLayerNeuronsMatrix: MPSMatrix!

    init(_ coldLayers: [Int], _ biases: [Double], _ weights: [Double]) {
        let cq = (device.makeCommandQueue())!
        commandQueue = cq

        topLayerNeuronsMatrix = HotNetGpu.makeMatrix(device, coldLayers[0])
        neuronsInMatrix = topLayerNeuronsMatrix
        neuronsInMatrix.data.label = "0"

        let CL = coldLayers

        var biasesIxL = 0, biasesIxR = 0
        var weightsIxL = 0, weightsIxR = 0

        hotLayers = zip(0..<CL.count - 1, 1..<CL.count).map { upperLayerIx, lowerLayerIx in
            let cNeuronsIn = CL[upperLayerIx]
            let cNeuronsOut = CL[lowerLayerIx]

            biasesIxR += cNeuronsOut
            weightsIxR += cNeuronsIn * cNeuronsOut

            neuronsOutMatrix = HotNetGpu.makeMatrix(device, cNeuronsOut)
            neuronsOutMatrix.data.label = "[Buffer \(lowerLayerIx)], \(cNeuronsOut) columns"

            let hotLayer = HotLayerGpu(
                biases[biasesIxL..<biasesIxR], device,
                neuronsInMatrix, neuronsOutMatrix,
                weights[weightsIxL..<weightsIxR]
            )

            neuronsInMatrix = neuronsOutMatrix
            biasesIxL = biasesIxR
            weightsIxL = weightsIxR

            return hotLayer
        }
    }

    func driveSignal(
        _ sensoryInputs: [Double], _ onComplete: @escaping ([Double]) -> Void
    ) {
        let commandBuffer = (commandQueue.makeCommandBuffer())!

        HotNetGpu.chargeMatrix(topLayerNeuronsMatrix.data, sensoryInputs[...])

        hotLayers.forEach { layer in layer.chargeCommandBuffer(commandBuffer) }

        commandBuffer.addCompletedHandler { _ in
            let motorOutputs = self.hotLayers.last!.getComputeOutput()
            onComplete(motorOutputs)
        }

        commandBuffer.commit()
    }
}

extension HotNetGpu {
    static func chargeMatrix(_ data: MTLBuffer, _ rawValues: ArraySlice<Double>) {
        let dContents = data.contents()

        zip(stride(from: 0, to: rawValues.count * NumberSize, by: NumberSize), rawValues).forEach { z in
            let (byteOffset, rawValue) = (z.0, Number(z.1))

            dContents.storeBytes(of: rawValue, toByteOffset: byteOffset, as: Number.self)
        }
    }

    static func makeMatrix(_ device: MTLDevice, _ rawValues: ArraySlice<Double>) -> MPSMatrix {
        let rowStride = MPSMatrixDescriptor.rowBytes(fromColumns: rawValues.count, dataType: NumberTypeInGPU)
        let d = MPSMatrixDescriptor(dimensions: 1, columns: rawValues.count, rowBytes: rowStride, dataType: NumberTypeInGPU)

        let inputBuffer = (device.makeBuffer(
            length: d.matrixBytes, options: MTLResourceOptions.storageModeManaged
        ))!

        chargeMatrix(inputBuffer, rawValues)

        return MPSMatrix(buffer: inputBuffer, descriptor: d)
    }

    static func makeMatrix(_ device: MTLDevice, _ cColumns: Int) -> MPSMatrix {
        let rowStride = MPSMatrixDescriptor.rowBytes(fromColumns: cColumns, dataType: NumberTypeInGPU)
        let d = MPSMatrixDescriptor(dimensions: 1, columns: cColumns, rowBytes: rowStride, dataType: NumberTypeInGPU)

        return MPSMatrix(device: device, descriptor: d)
    }
}