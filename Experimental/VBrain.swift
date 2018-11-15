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
import SpriteKit

class VBrain {
    var brain: BrainProtocol!
    let gameScene: GameScene
    var spacer: Spacer!
    var vNeurons = [SKShapeNode]()
    var vTestInputs = [SKLabelNode]()
    var vTestOutputs = [SKLabelNode]()
    
    init(gameScene: GameScene, brain: BrainProtocol) {
        guard let _ = NSScreen.main?.frame else {
            fatalError("Something isn't working with the screen size")
        }
        
        self.gameScene = gameScene
        self.brain = brain
    }
    
    func displayBrain() {
        brain.show()
        gameScene.removeAllChildren()
        
        self.spacer = Spacer(layersCount: brain.layers.count, displaySize: gameScene.size)
        drawNeuronLayers(brain.layers, spacer: spacer)
    }
    
    func reset() {
        brain = nil
        vNeurons = [SKShapeNode]()
        vTestInputs = [SKLabelNode]()
        vTestOutputs = [SKLabelNode]()
    }
    
    func setBrain(_ brain: BrainProtocol) {
        self.brain = brain
    }
    
    func tick() {
        gameScene.removeChildren(in: vTestInputs + vTestOutputs)
        
        let lambda = { (inputs: [Double], yIndex: Int) -> () in
            for (ix, input) in zip(0..., inputs) {
                let p = self.spacer.getPosition(neuronsThisLayer: inputs.count, xIndex: ix, yIndex: yIndex)
                let n = SKLabelNode(text: String(input))
                
                n.position = p
                
                self.vTestOutputs.append(n)
                self.gameScene.addChild(n)
            }
        }
        #if false
        let testInputs = breeder.bestBrainMostRecentInputs
        let testOutputs = breeder.bestBrainMostRecentOutputs
        
        lambda(testInputs, 0)
        lambda(testOutputs, testOutputs.count - 1)
        #endif
    }
    
    struct Spacer {
        let layersCount: Int
        let displaySize: CGSize
        
        init(layersCount: Int, displaySize: CGSize) {
            self.layersCount = layersCount
            self.displaySize = displaySize
        }
        
        func getVSpacing() -> Int {
            return Int(displaySize.height) / (layersCount + 1)
        }
        
        func getPosition(neuronsThisLayer: Int, xIndex: Int, yIndex: Int) -> CGPoint {
            let vSpacing = getVSpacing()
            let vTop = Int(displaySize.height) / 2 - vSpacing
            
            let hSpacing = Int(displaySize.width) / neuronsThisLayer
            let hLeft = (Int(-displaySize.width) + hSpacing) / 2
            
            return CGPoint(x: hLeft + xIndex * hSpacing, y: vTop - yIndex * vSpacing)
        }
    }
}

extension VBrain {
    func drawNeuronLayers(_ layers: [Expresser.Layer], spacer: Spacer) {
        var previousLayerPoints = [CGPoint]()
        
        for (i, layer) in zip(0..., layers) {
            if layer.neurons.isEmpty { /* print("No neurons in this layer");*/ continue }
            let spacer = Spacer(layersCount: layers.count, displaySize: gameScene.size)
            
            var currentLayerPoints = [CGPoint]()
            
            for (j, neuron) in zip(0..<layer.neurons.count, layer.neurons) {
                let vNeuron = SKShapeNode(circleOfRadius: 2)
                vNeuron.fillColor = .yellow
                
                let position = spacer.getPosition(neuronsThisLayer: layer.neurons.count, xIndex: j, yIndex: i)
                vNeuron.position = position
                currentLayerPoints.append(position)
                
                if !previousLayerPoints.isEmpty { drawConnections(from: previousLayerPoints, to: neuron, at: position) }
                
                self.vNeurons.append(vNeuron)
                gameScene.addChild(vNeuron)
            }
            previousLayerPoints = currentLayerPoints
        }
    }
    
    func drawConnections(from previousLayerPoints: [CGPoint], to neuron: Expresser.Neuron, at neuronPosition: CGPoint) {
        for (previousLayerPoint, active) in zip(previousLayerPoints, neuron.activators) {
            let linePath = CGMutablePath()
            linePath.move(to: neuronPosition)
            linePath.addLine(to: previousLayerPoint)
            
            let line = SKShapeNode(path: linePath)
            line.strokeColor = active ? .green : .gray
            gameScene.addChild(line)
        }
    }
}
