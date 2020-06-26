import Foundation

struct Grid {
    private static var theGrid: Grid!

    let core:    GridCore
    let indexer: GridIndexer
    let manna:   GridManna

    static var gridDimensionsCells: AKSize { theGrid.core.gridDimensionsCells }
    static var portalDimensionsPix: CGSize { theGrid.core.portalDimensionsPix }

    static func makeGrid(
        cellDimensionsPix: CGSize, portalDimensionsPix: CGSize,
        maxCSenseRings: Int, funkyCellsMultiplier: CGFloat?
    ) {
        theGrid = .init(
            cellDimensionsPix, portalDimensionsPix, maxCSenseRings,
            funkyCellsMultiplier
        )
    }

    private init(
        _ cellDimensionsPix: CGSize, _ portalDimensionsPix: CGSize,
        _ maxCSenseRings: Int, _ funkyCellsMultiplier: CGFloat?
    ) {
        self.indexer = .init(maxCSenseRings: maxCSenseRings)

        core = .init(
            cellDimensionsPix: cellDimensionsPix,
            portalDimensionsPix: portalDimensionsPix,
            maxCSenseRings: maxCSenseRings,
            funkyCellsMultiplier: funkyCellsMultiplier
        )

        manna =   GridManna()
    }
}

extension Grid {
    static func plantManna(at absoluteIndex: Int) -> Manna {
        return theGrid.manna.plantManna(at: absoluteIndex)
    }

//    static func vacate(_ arkon: Stepper) {
//        theGrid.arkons.vacate(cell: arkon.sensorPad.centerSensor.liveGridCell)
//    }
//
//    static func plantArkon(_ arkonSensorPad: SensorPad, in cell: GridCell) {
//        theGrid.arkons.plant(arkonSensorPad, in: cell)
//    }
}
//
//extension Grid {
//    static func attachArkonToGrid(
//        _ newborn: Stepper, _ onComplete: @escaping () -> Void
//    ) {
//        theGrid.sync.attachArkonToGrid(newborn, onComplete)
//    }
//
//    static func detachArkonFromGrid(at absoluteIndex: Int) {
//        theGrid.sync.completeDeferredLockRequest(absoluteIndex)
//    }
//}
//
extension Grid {
    static func cellAt(_ localIx: Int, from centerGridCell: GridCell) -> (GridCell, AKPoint) {
        theGrid.indexer.localIndexToRealGrid(localIx, from: centerGridCell)
    }

    static func first(
        fromCenterAt absoluteGridIndex: Int, cCells: Int,
        where predicate: @escaping (GridCell, AKPoint) -> Bool
    ) -> (GridCell, AKPoint)? {
        theGrid.indexer.first(
            fromCenterAt: absoluteGridIndex, cCells: cCells, where: predicate
        )
    }

    static func first(
        fromCenterAt centerCell: GridCell, cCells: Int,
        where predicate: @escaping (GridCell, AKPoint) -> Bool
    ) -> (GridCell, AKPoint)? {
        theGrid.indexer.first(
            fromCenterAt: centerCell, cCells: cCells, where: predicate
        )
    }

    static func cellAt(_ absoluteIndex: Int) -> GridCell    { theGrid.core.cellAt(absoluteIndex) }
    static func cellAt(_ gridPoint: AKPoint) -> GridCell    { theGrid.core.cellAt(gridPoint) }
    static func mannaAt(_ absoluteIndex: Int) -> Manna?     { theGrid.manna.mannaAt(absoluteIndex) }
}

//    static func moveArkon(
//        from sourceAbsoluteIndex: Int, toGridCell: GridCell
//    ) {
//        theGrid.arkons.moveArkon(from: sourceAbsoluteIndex, toGridCell: toGridCell)
//    }
//
//    static func placeNewborn(_ newborn: Stepper, at absoluteIndex: Int) {
//        theGrid.arkons.placeNewborn(newborn, at: absoluteIndex)
//    }
//}
//
extension Grid {
//    static func absoluteIndex(of point: AKPoint) -> Int {
//        theGrid.core.absoluteIndex(of: point)
//    }
//
    static func gridPosition(of index: Int) -> AKPoint {
        theGrid.core.gridPosition(of: index)
    }
//
//    static func lockRandomCell(_ onComplete: @escaping (GridCell) -> Void) {
//        theGrid.sync.lockRandomCell(onComplete)
//    }

    static func randomCellIndex() -> Int {
        let cCellsInGrid = theGrid.core.gridDimensionsCells.area()
        return Int.random(in: 0..<cCellsInGrid)
    }

    static func randomCell() -> GridCell { cellAt(randomCellIndex()) }
}
