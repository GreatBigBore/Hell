import Foundation

class CellSensor {
    var iHaveTheLiveConnection = false
    var liveGridCell: GridCell!
    let sensorPadLocalIndex: Int
    var virtualGridPosition: AKPoint?

    init(_ sensorPadLocalIndex: Int) { self.sensorPadLocalIndex = sensorPadLocalIndex }

    func engage(with cell: GridCell, virtualPosition vp: AKPoint?, gridIsLocked: Bool) {
        assert(gridIsLocked)

        liveGridCell = cell
        Debug.log(level: 213) { " engage() for cell at \(liveGridCell.properties.gridPosition)" }

        self.iHaveTheLiveConnection = !cell.lock.isLocked
        if self.iHaveTheLiveConnection { cell.lock.isLocked = true }

        self.virtualGridPosition =
            (vp == cell.properties.gridPosition) ? nil : vp

        self.liveGridCell = cell
    }

    func disengage() {
        let iHadTheLiveConnection = self.iHaveTheLiveConnection

        self.iHaveTheLiveConnection = false
        self.virtualGridPosition = nil

        if iHadTheLiveConnection {
            let cellIsOccupied = liveGridCell.contents.hasArkon()
            liveGridCell.lock.releaseLock(cellIsOccupied)
        }
    }
}
