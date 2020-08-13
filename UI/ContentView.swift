import SpriteKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var randomer: AKRandomNumberFakerator

    var body: some View {
        HStack {
            Spacer()

            SundialView(.simpleSineAddition)
                .frame(width: ArkoniaLayout.SeasonFactorView.frameWidth)

            VStack {
                HudView()
                    .frame(height: ArkoniaLayout.ContentView.hudHeight)

                GameView(scene: ArkoniaScene())
//                    .sheet(isPresented: $randomer.isBusy) {
//                        LlamaProgressView().environmentObject(self.randomer)
//                    }
            }

            VStack {
                ForEach(0..<1) { _ in
                    FoodSuccessLineChart()
                        .frame(
                            width: ArkoniaLayout.LineChartView.frameWidth,
                            height: ArkoniaLayout.LineChartView.frameHeight
                        )
                        .padding([.trailing, .bottom, .leading])
                        .environmentObject(FoodSuccessLineChartControls.controls)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
