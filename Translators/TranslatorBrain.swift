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

extension Translators {
    class Brain: NeuralNetProtocol {
        var fitnessScore: Double?
        
        func generateRandomSensoryInput() -> [Double] {
            return [0]
        }
        
        var layers = [Translators.Layer]()
        var underConstruction: Translators.Layer!
        
        var firstLayer = true
        
        func makeLayer() -> Layer {
            return Layer(layerSSInBrain: layers.count)
        }
        
        func addActivator(_ active: Bool) { underConstruction?.addActivator(active) }
        
        func addWeight(_ value: ValueDoublet) { underConstruction?.addWeight(value) }
        func addWeight(_ baseline: Double, _ value: Double) { underConstruction?.addWeight(baseline, value) }

        func closeLayer() {
            if let u = underConstruction {
                closeNeuron()
                
                // Just discard empty layers
                if !u.neurons.isEmpty { layers.append(u) }
                
                underConstruction = nil
//                print("Brain closes layer")
            }
            else { print("unknown layer?") }
        }
        
        func closeNeuron() { underConstruction?.closeNeuron() }

        func setInputs(_ inputs: [Int]) {
            
        }
        
        func connectLayers() throws {
            var previousLayer: Layer?
            
            for (which, layer) in zip(0..., layers) {
                guard let p = previousLayer else { previousLayer = layer; layer.setTopLayerInputPorts(); continue }
                let isMotorNeuronLayer = ((which + 1) == self.layers.count)
                
                let ctNeurons = p.neurons.count
                let pell = previousLayer
                let ismnl = isMotorNeuronLayer
                try layer.connectNeurons(ctAvailableInputs: ctNeurons, previousLayer: pell, isMotorNeuronLayer: ismnl)

                previousLayer = layer
            }
        }
        
        func endOfStrand() throws {
            closeNeuron()
            closeLayer()
            
            if layers.isEmpty { throw SelectionError.nonViableBrain }

            for layer in layers {
                guard !layer.neurons.isEmpty else { throw SelectionError.nonViableBrain }
                layer.endOfStrand()
            }
        }
        
        func newLayer() {
            guard underConstruction == nil else { fatalError() }
            underConstruction = makeLayer()
//            print("Brain creates Layer(\(underConstruction!))")
        }
        
        func newNeuron() { underConstruction?.newNeuron() }

        func setBias(_ value: ValueDoublet) { underConstruction?.setBias(value) }
        func setBias(_ baseline: Double, _ value: Double) { underConstruction?.setBias(baseline, value) }
        
        func setOutputFunction(_ function: @escaping NeuronOutputFunction) { underConstruction?.setOutputFunction(function) }

        func setThreshold(_ value: ValueDoublet) { underConstruction?.setThreshold(value) }
        func setThreshold(_ baseline: Double, _ value: Double) { underConstruction?.setThreshold(baseline, value) }
        
        func show(tabs: String, override: Bool = false) {
            if Utilities.thereBeNoShowing && !override { return }
            print("Brain: ")
            for layer in layers { layer.show(tabs: "", override: override) }
            print()
        }
        
        func stimulate(inputs: [Double]) -> [Double]? {
            var previousLayerOutputs = inputs
            
            for layer in self.layers {
                if previousLayerOutputs.isEmpty { return nil }

                previousLayerOutputs =
                    layer.stimulate(inputs: previousLayerOutputs)
            }
            
            if previousLayerOutputs.isEmpty { return nil }
            return previousLayerOutputs
        }
    }
}
