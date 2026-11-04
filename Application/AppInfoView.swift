import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Practice") {
                    Text(
                        "Train with repeated interval cues, then test your sense of time without a countdown. Review calibration for each interval."
                    )
                    Text("Phone and Watch work independently. Their histories stay separate.")
                    Text("Training currently needs this app open. Locking or leaving the app interrupts it.")
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
