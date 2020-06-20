import SpriteKit

class ArkonEmbryo {
    var birthingCell: GridCellConnector?
    var fishDay = Fishday(birthday: 0, cNeurons: 0, fishNumber: 0)
    var metabolism: Metabolism?
    var name: ArkonName?
    var net: Net?
    var netDisplay: NetDisplay?
    var newborn: Stepper?
    var noseSprite: SKSpriteNode?
    var parentArkon: Stepper?
    var sensorPad: SensorPad?
    var thoraxSprite: SKSpriteNode?
    var toothSprite: SKSpriteNode?

    // Strong ref to the spawn object for when we're born supernaturally.
    // We need it to exist until we're ready to disconnect, which comes late
    // in the process, and I don't feel like rewriting anything else at the moment
    var supernaturalSpawnThing: Spawn?

    init(_ parentArkon: Stepper?, _ supernaturalSpawnThing: Spawn?) {
        Debug.log(level: 204) { "ArkonEmbryo" }
        self.parentArkon = parentArkon
        self.supernaturalSpawnThing = supernaturalSpawnThing

        if parentArkon != nil { self.sensorPad = nil; return }
    }

    deinit {
        Debug.log(level: 205) { "~ArkonEmbryo" }
    }
}

extension ArkonEmbryo {
    func buildSprites() {
        hardAssert(Display.displayCycle == .updateStarted) { "hardAssert at \(#file):\(#line)" }

        toothSprite = SpriteFactory.shared.teethPool.makeSprite()
        noseSprite = SpriteFactory.shared.nosesPool.makeSprite()
        thoraxSprite = SpriteFactory.shared.arkonsPool.makeSprite()

        toothSprite!.alpha = 1
        toothSprite!.colorBlendFactor = 1
        toothSprite!.color = .red
        toothSprite!.zPosition = 4

        noseSprite!.addChild(toothSprite!)
        noseSprite!.alpha = 1
        noseSprite!.colorBlendFactor = 1
        noseSprite!.color = .blue
        noseSprite!.setScale(Arkonia.noseScaleFactor)
        noseSprite!.zPosition = 3

        // We don't set the arkon's main sprite position here; we set it later,
        // after we have a sensor pad and stuff set up
        thoraxSprite!.addChild(noseSprite!)
        thoraxSprite!.setScale(Arkonia.arkonScaleFactor * 1.0 / Arkonia.zoomFactor)
        thoraxSprite!.colorBlendFactor = 0.5
        thoraxSprite!.alpha = 1
        thoraxSprite!.zPosition = 2

        let noseColor: SKColor = (parentArkon == nil) ? .systemBlue : .yellow
        Debug.debugColor(thoraxSprite!, .blue, noseSprite!, noseColor)
    }

    func buildGuts(_ onComplete: @escaping () -> Void) {
        let nn = parentArkon?.net

        Net.makeNet(nn?.netStructure, nn?.pBiases, nn?.pWeights) { newNet in
            let ns = newNet.netStructure
            self.sensorPad = .makeSensorPad(ns.sensorPadCCells)
            self.metabolism = Metabolism(cNeurons: ns.cNeurons)
            self.net = newNet
            onComplete()
        }
    }

    func detachFromParent(_ birthingCell: GridCellConnector) {
        self.birthingCell = birthingCell

        if birthingCell.isHot {
            // The parent arkon has chosen a cell for us from among her locked
            // sensor pad cells. We don't need to do anything else, just start
            // eating
            launchNewborn()
        } else {
            // We have a random cell from on high; we need to lock it
            // before we can inhabit it. We will also come here if the parent
            // arkon couldn't find a suitable landing place for the newborn
            sensorPad!.engageGrid(centerIsPreLocked: false, launchNewborn)
        }
    }

    func placeNewbornOnGrid(_ newborn: Stepper) {
        let bc = sensorPad!.unsafeCellConnectors[0]

        thoraxSprite!.position = bc!.coreCell!.scenePosition

        Grid.shared.placeArkon(newborn, atIndex: sensorPad!.centerAbsoluteIndex)
    }

    func registerBirth() {
        name = ArkonName.makeName()
        fishDay = Census.shared.registerBirth(name!, parentArkon, net!)
    }
}

extension ArkonEmbryo {
    func launchNewborn() {
        Debug.log(level: 205) { "launchNewborn \(name!)" }
        MainDispatchQueue.async(execute: launchNewborn_B)
    }

    private func launchNewborn_B() {
        Debug.log(level: 205) { "launchNewborn_B \(name!)" }
        self.newborn = Stepper(self)

        // The grid creates a strong ref to the new arkon...
        placeNewbornOnGrid(newborn!)

        // ...so the embryo and all its trappings can go away now; here
        // we nil the hacky circular reference that's been holding it
        // together all this time
        supernaturalSpawnThing = nil

        SceneDispatch.shared.schedule(launchNewborn_C)
    }

    private func launchNewborn_C() {
        Debug.log(level: 205) {
            "launchNewborn_C, real stepper now \(self.newborn!.name)"
            + " at \(self.newborn!.sensorPad.centerAbsoluteIndex)"
        }

        SpriteFactory.shared.arkonsPool.attachSprite(newborn!.thorax)

        let rotate = SKAction.rotate(byAngle: -2 * CGFloat.tau, duration: 0.5)
        newborn!.thorax.run(rotate, completion: newborn!.dispatch.tickLife)
    }
}
