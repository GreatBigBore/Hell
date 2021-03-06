import CoreGraphics

enum ArkoniaLayout {
    enum AlmanacView {}
    enum ButtonsView {}
    enum ContentView {}
    enum DaylightFactorView {}
    enum SeasonFactorView {}
}

extension ArkoniaLayout.AlmanacView {
    static let frameWidth: CGFloat = 225
    static let labelFontSize: CGFloat = 14
    static let meterFontSize: CGFloat = 12
}

extension ArkoniaLayout.ButtonsView {
    static let buttonLabelsFrameMinWidth: CGFloat = 50
}

extension ArkoniaLayout.ContentView {
    static let hudHeight: CGFloat = 125
}

extension ArkoniaLayout.DaylightFactorView {
    static let sunstickFrameWidth: CGFloat = 10
    static let sunstickFrameHeight: CGFloat = 100
    static let sunstickCornerRadius: CGFloat = 5

    static let sunFrameWidth: CGFloat = 20
    static let sunFrameHeight: CGFloat = 20
}

extension ArkoniaLayout.SeasonFactorView {
    static let frameWidth: CGFloat = 40

    static let bgFrameWidth: CGFloat = 40
    static var bgFrameHeight = CGFloat.zero // Set by the app startup

    static let stickGrooveFrameWidth: CGFloat = 10
    static var stickGrooveFrameHeight = CGFloat.zero // Set by the app startup

    static let tempIndicatorFrameWidth = bgFrameWidth
    static let tempIndicatorFrameHeight: CGFloat = 3
}
