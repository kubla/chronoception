import SwiftUI

@main
struct ChronoceptionApp: App {
    @State private var store = PracticeStore()

    var body: some Scene {
        WindowGroup {
            PracticeView(store: store)
                .tint(PracticeStyle.systemTint)
                #if os(iOS)
                    .preferredColorScheme(.light)
                #endif
        }
    }
}

enum PracticeStyle {
    static let systemTint = Color(red: 0.12, green: 0.39, blue: 0.35)
    #if os(watchOS)
        static let accent = Color(red: 0.60, green: 0.83, blue: 0.73)
        static let buttonInk = Color(red: 0.045, green: 0.075, blue: 0.07)
        static let toolbarInk = Color(red: 0.94, green: 0.93, blue: 0.86)
        static let background = Color(red: 0.045, green: 0.075, blue: 0.07)
        static let ink = Color(red: 0.94, green: 0.93, blue: 0.86)
        static let surface = Color(red: 0.12, green: 0.19, blue: 0.17)
        static let heroSize: CGFloat = 30
        static let markSize: CGFloat = 96
    #else
        static let accent = Color(red: 0.12, green: 0.39, blue: 0.35)
        static let buttonInk = Color.white
        static let toolbarInk = accent
        static let background = Color(red: 0.97, green: 0.96, blue: 0.92)
        static let ink = Color(red: 0.12, green: 0.20, blue: 0.19)
        static let surface = Color.white.opacity(0.65)
        static let heroSize: CGFloat = 46
        static let markSize: CGFloat = 230
    #endif
}
