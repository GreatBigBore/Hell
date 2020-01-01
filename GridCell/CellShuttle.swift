import SpriteKit

class CellShuttle {
    var consumedContents = GridCell.Contents.nothing
    weak var consumedSprite: SKSpriteNode?
    var didMove = false
    var fromCell: HotKey?
    var toCell: HotKey?

    init(_ fromCell: HotKey?, _ toCell: HotKey) {
        self.fromCell = fromCell; self.toCell = toCell
    }

    func move() {
        consumedContents = .nothing
        consumedSprite = nil

        // No fromCell means we didn't move
        guard let f = fromCell else { return }
        guard let t = toCell else { preconditionFailure() }

        consumedContents = t.contents
        consumedSprite = t.sprite

        t.contents = f.contents
        t.sprite = f.sprite

        f.contents = .nothing
        f.sprite = nil

        didMove = true
    }

    func transferKeys(to winner: Stepper) -> CellShuttle {
        toCell?.transferKey(to: winner)
//        fromCell?.transferKey(to: winner)
        return self
    }
}
