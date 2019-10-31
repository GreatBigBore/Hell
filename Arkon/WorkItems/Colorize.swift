import GameplayKit

final class Colorize: AKWorkItem {
    var stats: World.StatsCopy!

    override func go() { aColorize() }

}

extension Colorize {
    func aColorize() {
        assert(runningAsBarrier == true)
        guard let dp = self.dispatch else { fatalError() }
        guard let st = self.stepper else { fatalError() }

        stats = World.stats.copy()

        let age = stats.currentTime - st.birthday
        st.colorizeProper(dp, age)
        dp.shift()
    }
}

extension Stepper {

    func colorizeProper(_ dispatch: Dispatch, _ myAge: Int) {
        let ef = metabolism.fungibleEnergyFullness
        nose.color = ColorGradient.makeColor(Int(ef * 100), 100)

        let baseColor: Int
        if fishNumber > 0 {
            baseColor = 0xFF_00_00
        } else {
            baseColor = (metabolism.spawnEnergyFullness > 0) ?
                Wangkhi.brightColor : Wangkhi.standardColor
        }

        let four: CGFloat = 4
        self.sprite.color = ColorGradient.makeColorMixRedBlue(
            baseColor: baseColor,
            redPercentage: metabolism.spawnEnergyFullness,
            bluePercentage: max((four - CGFloat(myAge)) / four, 0.0)
        )

        self.sprite.colorBlendFactor = metabolism.oxygenLevel
    }
}
