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

class VNeuron: VDisplayable {
    let bias: Double
    let id: KIdentifier
    var inputSources: [VInputSource]
    weak var portal: SKNode!
    let output: Double
    private(set) var position: CGPoint?

    init(id: KIdentifier, portal: SKNode, bias: Double, inputSources: [VInputSource],
         output: Double)
    {
        self.id = id
        self.bias = bias
        self.inputSources = inputSources
        self.portal = portal
        self.output = output
    }

    func drawConnections(on skNeuron: SKSpriteNode) {
        precondition(self.position != nil, "My position isn't set")
        inputSources.forEach {
            precondition($0.source.position != nil, "His position isn't set")
            drawLine(from: self.position!, to: $0.source.position!)
        }
    }

    func drawLine(from start: CGPoint, to end: CGPoint) {
        let line = VNeuron.drawLine(from: start, to: end)
        portal.addChild(line)
    }

    @discardableResult
    static func drawLine(from start: CGPoint, to end: CGPoint) -> SKShapeNode {
        let linePath = CGMutablePath()

        linePath.move(to: start)
        linePath.addLine(to: end)

        let line = SKShapeNode(path: linePath)

        line.strokeColor = .green
        line.zPosition = ArkonCentral.vConnectorZPosition

        return line
    }

    func drawMyself(spacer: VSpacer, layerRole: VLayer.LayerRole)
        -> SKSpriteNode
    {
        let texture: SKTexture = {
            switch layerRole {
            case .hiddenLayer: return ArkonCentral.blueNeuronSpriteTexture
            case .senseLayer: return ArkonCentral.orangeNeuronSpriteTexture
            case .motorLayer: return ArkonCentral.greenNeuronSpriteTexture
            }
        }()

        let sprite = SKSpriteNode(texture: texture)
//        sprite.physicsBody = SKPhysicsBody(circleOfRadius: 15.0)

        sprite.setScale(ArkonCentral.vNeuronScale)
        sprite.position = unscale(spacer.getPosition(for: self))
        sprite.zPosition = ArkonCentral.vNeuronZPosition
        self.position = sprite.position
        portal.addChild(sprite)
        return sprite
    }

    func unscale(_ position: CGPoint) -> CGPoint {
        return position * ArkonCentral.vNeuronAntiscale
    }

    func visualize(spacer: VSpacer, layerRole: VLayer.LayerRole) {
        let skNeuron = drawMyself(spacer: spacer, layerRole: layerRole)
        drawConnections(on: skNeuron)
    }
}