import SpriteKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            Spacer()

            SeasonFactorView()
                .frame(width: ArkoniaLayout.SeasonFactorView.frameWidth)
                .environmentObject(Clock.shared.seasonalFactors)

            VStack {
                HStack {
                    AlmanacView().environmentObject(Clock.shared.seasonalFactors)
                        .frame(width: ArkoniaLayout.AlmanacView.frameWidth)

                    AuxScalarHudView()
                        .frame(width: ArkoniaLayout.AlmanacView.frameWidth)

                    LineChartView()
                        .environmentObject(LineChartViews.lineChartData)

                    ButtonsView()
                }
                .frame(height: ArkoniaLayout.ContentView.hudHeight)

                GameView(scene: ArkoniaScene())
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}