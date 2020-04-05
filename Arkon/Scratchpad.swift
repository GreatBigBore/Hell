import CoreGraphics
import Foundation

class Scratchpad {
    var battle: (Stepper, Stepper)?
    var canSpawn = false
    var cellShuttle: CellShuttle?
    var spreader = Int.random(in: 0..<10)
    var spreading = 0
    weak var dispatch: Dispatch?
    var engagerKey: GridCellKey?
    var isApoptosizing = false
    var name = ArkonName.makeName(.nothing, 0)
    weak var parentNet: Net?
    var plotter: Plotter?
    var senseGrid: CellSenseGrid?
    var sensesConnector: SensesConnector?
    weak var stepper: Stepper!
    var co2Counter: CGFloat = 0
    var debugTimer: __uint64_t = 0
    var debugStart: __uint64_t = 0
    var debugStop: __uint64_t = 0

    var gridInputs = [Double]()

    var currentTime: Int = 0
    var currentEntropyPerJoule: Double = 0

    deinit {
        Debug.log(level: 146) { "Scratchpad deinit for \(name)" }
        if let hk = engagerKey as? HotKey {
            Debug.log(level: 146) { "release engager key for \(name)" }
            hk.releaseLock() }
        engagerKey = nil

        if let fc = cellShuttle?.fromCell {
            Debug.log(level: 146) { "release fromCell for \(name)" }
            fc.releaseLock() }
        cellShuttle?.fromCell = nil

        if let tc = cellShuttle?.toCell {
            Debug.log(level: 146) { "release toCell for \(name)" }
            tc.releaseLock() }
        cellShuttle?.toCell = nil

        senseGrid?.cells.forEach { cellKey in
            Debug.log(level: 146) { "release senseGrid cell for \(name) -> \(cellKey is HotKey)" }
            (cellKey as? HotKey)?.releaseLock() }
        senseGrid = nil
    }
}
