import SpriteKit

final class MoveSprite: Dispatchable {
    weak var scratch: Scratchpad?
    var wiLaunch: DispatchWorkItem?

    init(_ scratch: Scratchpad) {
        self.scratch = scratch
        // maybe we need a barrier to protect calls to sprite.run?
        self.wiLaunch = DispatchWorkItem(flags: .barrier, block: launch_)
    }

    func launch() {
        guard let w = wiLaunch else { fatalError() }
        Grid.shared.concurrentQueue.async(execute: w)
    }

    private func launch_() { moveSprite() }

    func moveSprite() {
        guard let (ch, dp, st) = scratch?.getKeypoints() else { fatalError() }

        let gcc = ch.stage
        let moveDuration: TimeInterval = 0.1
        let position = gcc.to.randomScenePosition ?? gcc.to.scenePosition

        let moveAction = gcc.willMove ?
            SKAction.move(to: position, duration: moveDuration) :
            SKAction.wait(forDuration: moveDuration)

        st.sprite.run(moveAction) { [unowned self] in
            dp.moveStepper(self.wiLaunch!)
        }
    }
}
