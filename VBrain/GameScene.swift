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
  

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private var brain: NeuralNetProtocol!
    private var decoder: Decoder!
    private var vBrain: VBrain!

    var generationSS = 0
    var firstUpdate = true
    var update = true
//    var genome = "B(b[42]v[42])_W(b[-0.71562]v[-0.71562])_W(b[-33.21311]v[-33.21311])_N_A(false)_W(b[-76.33163]v[-76.33163])_A(false)_W(b[-17.40379]v[-17.40379])_T(b[-20.08699]v[-20.08699])_A(true)_T(b[-49.80827]v[-49.80827])_W(b[-88.31035]v[-88.31035])_T(b[-66.83028]v[-66.83028])_N_A(false)_A(false)_L_B(b[87.97370]v[87.97370])_A(true)_N_T(b[-47.82303]v[-47.82303])_"
    var frameCount = 0
    var currentGeneration = [Genome]()
    var selection = [Genome]()
    var testSubjectSetup = TSNumberGuesserSetup()

    override func didMove(to view: SKView) {
        decoder = Decoder()

        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        generationSS = 0
        update = true
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:
            if let label = self.label {
                label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
            }
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    // With deepest gratitude to Stack Overflow dude
    // https://stackoverflow.com/users/2346164/gilian-joosen
    // https://stackoverflow.com/a/26787701/1610473
    //
    func returnChar(_ theEvent: NSEvent) -> Character? {
        let s: String = theEvent.characters!
        for char in s{ return char }
        return nil
    }
    
    func nextBrain() {
        if selection.isEmpty { print("That's all, folks!"); fatalError() }
        
        let cg = selection.remove(at: 0)
        decoder.setInput(to: cg).decode()

        self.brain = Translators.t.getBrain()
        self.brain.show(tabs: "", override: false)
        
        vBrain.displayBrain(self.brain)
        
        update = true
    }

    override func keyUp(with event: NSEvent) {
        nextBrain()
    }
    
    var whichGenome = 1
    override func update(_ currentTime: TimeInterval) {
        frameCount += 1
        if frameCount < 60 { return }
        frameCount = 0
        
        for _ in 0..<1 { self.testSubjectSetup.tick() }
        decoder.setInput(to: Breeder.bb.getBestGenome()).decode()
        self.brain = Translators.t.getBrain()
        vBrain = VBrain(gameScene: self, brain: self.brain)
        vBrain.displayBrain(self.brain)
    }

}

