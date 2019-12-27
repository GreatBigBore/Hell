import CoreGraphics

extension GridCell {
    static func getRandomCell() -> GridCell {
        let wGrid = Grid.dimensions.wGrid
        let hGrid = Grid.dimensions.hGrid

        let wp = wGrid - 5, hp = hGrid - 5
        let ak = AKPoint.random(-wp..<wp, -hp..<hp)

        return GridCell.at(ak.x, ak.y)
    }

    static func getRandomEmptyCell() -> GridCell {
        var rg: GridCell!

        repeat {
            rg = getRandomCell()
        } while rg.contents.isOccupied()

        return rg
    }

    static func lockBirthPosition(parent: Stepper, name: String) -> HotKey {
        var randomGridCell: HotKey?
        var gridPointIndex = 0

        repeat {
            gridPointIndex += 1

            let p = parent.gridCell.getGridPointByIndex(gridPointIndex)

            guard let hk = GridCell.atIf(p)?.lockIf(ownerName: name)
                else { continue }

            randomGridCell = hk
        } while (randomGridCell?.contents ?? .invalid) != .nothing

        writeDebug("lockBirthPosition for parent \(six(parent.name)) at \(randomGridCell!.gridPosition)", scratch: parent.dispatch.scratch)
        return randomGridCell!
    }

    static func lockRandomEmptyCell(ownerName: String, onComplete: @escaping ((HotKey?) -> Void)) {
        Grid.shared.serialQueue.async {
            let hotKey = lockRandomEmptyCell(ownerName: ownerName)
            onComplete(hotKey)
        }
    }

    static var lockCount = 0

    static func lockRandomEmptyCell(ownerName: String) -> HotKey? {
        var randomGridCell: HotKey?

        repeat {
            let r = GridCell.getRandomEmptyCell()
            var ck: GridCellKey?
            r.lock(require: .degradeToCold, ownerName: ownerName) { ck = $0 }

            guard let hk = ck as? HotKey else { continue }

            randomGridCell = hk
        } while randomGridCell == nil

        Log.L.write("lockRandomEmptyCell at \(randomGridCell!.gridPosition)", level: 54)
        return randomGridCell!
    }
}