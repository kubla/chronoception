import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Practice") {
                    Text(
                        "Choose an interval. Tap when it feels complete. Each estimate gets early or late feedback."
                    )
                    Text("Phone and Watch work independently. Their histories stay separate.")
                }
                Section("Privacy") {
                    Text(
                        "Your practice history is stored locally. Chronoception has no account, advertising or analytics service."
                    )
                    .accessibilityIdentifier("privacy-summary")
                    Link(
                        "Privacy policy",
                        destination: URL(string: "https://kubla.github.io/chronoception/privacy.html")!
                    )
                    .foregroundStyle(PracticeStyle.accent)
                }
                Section("Support") {
                    Link(
                        "Report a problem",
                        destination: URL(string: "https://github.com/kubla/chronoception/issues")!
                    )
                    .foregroundStyle(PracticeStyle.accent)
                }
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(PracticeStyle.toolbarInk)
                }
            }
        }
    }
}
