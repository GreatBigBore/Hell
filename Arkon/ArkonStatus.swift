import Foundation
import SpriteKit

extension Arkon {
    typealias Update = (Bool, Bool) -> Void

    struct Status {
        init(fishNumber: Int) {
            self.fishNumber = fishNumber
        }

        mutating func postInit() {
            self.birthday = Display.shared.currentTime
        }

        var age: TimeInterval { return Display.shared.currentTime - birthday }
        var birthday: TimeInterval = 0
        let fishNumber: Int
        var isDuggarest = false
        var isOldest = false
    }
}
