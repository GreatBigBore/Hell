//swiftlint:disable unused_setter_value
import SpriteKit

protocol GridCellKey {
    var contents: GridCell.Contents { get }
    var gridPosition: AKPoint { get }
    var ownerName: String { get }
    var sprite: SKSpriteNode? { get }
}

struct ColdKey: GridCellKey {
    init(for cell: GridCell) {
        contents = cell.contents
        gridPosition = cell.gridPosition
        ownerName = cell.ownerName
        sprite = cell.sprite
    }

    let contents: GridCell.Contents
    let gridPosition : AKPoint
    let ownerName: String
    let sprite: SKSpriteNode?
}

class HotKey: GridCellKey, CustomDebugStringConvertible {
    private weak var cell_: GridCell?
    var bell: GridCell? { get { cell_ } set { preconditionFailure() } }

    var debugDescription: String {
        "\(bell?.gridPosition ?? AKPoint(x: -4242, y: -4242))"
    }

    var contents: GridCell.Contents {
        get { return cell_?.contents ?? .invalid }
        set { cell_?.contents = newValue }
    }

    var gridPosition: AKPoint {
        get { return cell_?.gridPosition ?? AKPoint(x: -4242, y: -4242) }
        set { preconditionFailure() }
    }

    var randomScenePosition: CGPoint? {
        get { return cell_?.randomScenePosition }
        set { preconditionFailure() }
    }

    var scenePosition: CGPoint {
        get { return cell_?.scenePosition ?? CGPoint(x: -42.42, y: -42.42) }
        set { preconditionFailure() }
    }

    var ownerName: String {
        get { return cell_?.ownerName ?? "empty hotkey" }
        set { cell_?.ownerName = newValue }
    }

    var sprite: SKSpriteNode? {
        get { return cell_?.sprite }
        set { cell_?.sprite = newValue }
    }

    init(for cell: GridCell, ownerName: String) {
        self.cell_ = cell
        cell.isLocked = true
        cell.ownerName = ownerName
        Log.L.write("HotKey at \(cell.gridPosition) for \(six(ownerName))", level: 51)
    }

    deinit { releaseLock() }

    func deactivate() {
        Log.L.write("deactivate for \(six(ownerName))", level: 60)
        self.cell_ = nil
    }

    func reengageRequesters() {
        guard let c = bell else { return }

        while true {
            guard let waitingStepper = c.getRescheduledArkon() else {
                Log.L.write("reengageRequesters empty", level: 61)
                return
            }
            if let dp = waitingStepper.dispatch, let st = dp.scratch.stepper {
                Log.L.write("reengageRequesters: \(six(st.name)) at \(self.gridPosition)", level: 63)
                dp.disengage()
                return
            }
        }
    }

    func releaseLock() {
        let wasLocked = cell_?.releaseLock() ?? false
        if wasLocked  { Log.L.write("releaseLock at \(cell_?.gridPosition ?? AKPoint(x: -42, y: -42)) for \(six(ownerName)) nil? \(cell_ == nil)", level: 63) }
        reengageRequesters()
        cell_ = nil
    }

    func transferKey(to winner: Stepper) {
        guard let c = cell_ else { fatalError() }
        precondition(c.isLocked)

        Log.L.write("transferKey from \(six(self.ownerName)) at \(gridPosition) to \(six(winner.name))", level: 59)

        self.ownerName = winner.name
        self.sprite = winner.sprite
    }
}

class NilKey: GridCellKey {
    //swiftlint:disable unused_setter_value
    var bell: GridCell? { get { nil } set { preconditionFailure() } }
    var contents: GridCell.Contents { get { .invalid } set { preconditionFailure() } }
    var gridPosition: AKPoint { get { AKPoint(x: -4242, y: -4242) } set { preconditionFailure() } }
    var ownerName: String { get { "invalid" } set { preconditionFailure() } }
    var sprite: SKSpriteNode?  { get { nil } set { preconditionFailure() } }
    //swiftlint:enable unused_setter_value
}