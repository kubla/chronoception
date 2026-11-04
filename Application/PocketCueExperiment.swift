#if os(iOS) || os(macOS)
    import ChronoceptionCore
    import Observation
    import SwiftUI
    import UserNotifications

    @MainActor
    protocol PocketNotificationService {
        func authorize() async throws -> Bool
        func pendingIdentifiers() async -> [String]
        func add(identifier: String, body: String, delay: Double) async throws
        func remove(identifiers: [String])
    }

    @MainActor
    final class SystemPocketNotifications: PocketNotificationService {
        private let center = UNUserNotificationCenter.current()

        func authorize() async throws -> Bool {
            try await center.requestAuthorization(options: [.alert, .sound])
        }

        func pendingIdentifiers() async -> [String] {
            await center.pendingNotificationRequests().map(\.identifier)
        }

        func add(identifier: String, body: String, delay: Double) async throws {
            let content = UNMutableNotificationContent()
            content.title = "Chronoception"
            content.body = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            try await center.add(
                UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }

        func remove(identifiers: [String]) {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    @MainActor @Observable
    final class PocketCueExperiment {
        enum Phase: Equatable {
            case loading, ready, requesting
            case scheduled(Int)
            case denied
            case failed(String)
        }

        private(set) var phase: Phase = .loading
        private let service: any PocketNotificationService
        private var requestIDs: [String] = []
        private var generation = UUID()
        private let prefix = "chronoception.pocket."

        init(service: (any PocketNotificationService)? = nil) {
            self.service = service ?? SystemPocketNotifications()
        }

        func refresh() async {
            guard phase != .requesting else { return }
            let token = generation
            let identifiers = await service.pendingIdentifiers()
            guard generation == token else { return }
            requestIDs = identifiers.filter { $0.hasPrefix(prefix) }
            phase = requestIDs.isEmpty ? .ready : .scheduled(requestIDs.count)
        }

        private func clearPending(token: UUID) async -> Bool {
            service.remove(identifiers: requestIDs)
            let identifiers = await service.pendingIdentifiers()
            guard generation == token else { return false }
            service.remove(identifiers: identifiers.filter { $0.hasPrefix(prefix) })
            requestIDs = []
            return true
        }

        func schedule(interval: PracticeInterval, repetitions: Int) async {
            guard (1...5).contains(repetitions) else { return }
            let token = UUID()
            generation = token
            phase = .requesting
            guard await clearPending(token: token) else { return }
            var identifiers: [String] = []
            do {
                let allowed = try await service.authorize()
                guard generation == token else { return }
                guard allowed else {
                    phase = .denied
                    return
                }
                let clock = ContinuousClock()
                let start = clock.now
                for index in 1...repetitions {
                    let elapsed = start.duration(to: clock.now).components
                    let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                    let remaining = Double(interval.seconds * index) - seconds
                    guard remaining > 0 else {
                        service.remove(identifiers: identifiers)
                        phase = .failed("Preparing cues took too long. Try a longer interval.")
                        return
                    }
                    let id = prefix + token.uuidString + "." + String(index)
                    identifiers.append(id)
                    requestIDs = identifiers
                    try await service.add(
                        identifier: id, body: "\(interval.label) · cue \(index) of \(repetitions)",
                        delay: remaining)
                    guard generation == token else {
                        service.remove(identifiers: identifiers)
                        await refresh()
                        return
                    }
                }
                phase = .scheduled(identifiers.count)
                await refresh()
            } catch {
                service.remove(identifiers: identifiers)
                if generation == token { phase = .failed(error.localizedDescription) }
            }
        }

        func cancel() async {
            let token = UUID()
            generation = token
            phase = .loading
            guard await clearPending(token: token) else { return }
            await refresh()
        }
    }

    #if os(iOS)
        struct PocketCueExperimentView: View {
            let interval: PracticeInterval
            let repetitions: Int
            @Bindable var experiment: PocketCueExperiment
            @Environment(\.dismiss) private var dismiss
            @Environment(\.scenePhase) private var scenePhase

            var body: some View {
                NavigationStack {
                    List {
                        Section("Pocket cue experiment") {
                            Text("\(repetitions) cues, \(interval.label) apart")
                            Text(
                                "Schedule notification cues, then lock your phone and try them in your pocket."
                            )
                            Text(
                                "Your sound, haptic and Focus settings control what you feel. Scheduled cues are not recorded as felt intervals or estimate accuracy."
                            )
                            .font(.footnote)
                        }
                        Section {
                            switch experiment.phase {
                            case .loading: ProgressView("Checking pending cues…")
                            case .ready: Text("No cues pending").accessibilityIdentifier("pocket-status")
                            case .requesting: ProgressView("Preparing cues…")
                            case .scheduled(let count):
                                Text(count == 1 ? "1 cue pending" : "\(count) cues pending")
                                    .accessibilityIdentifier("pocket-status")
                                Text(
                                    "You may lock your phone or close this sheet. Return here to end pending cues."
                                )
                            case .denied:
                                Text("Allow Chronoception notifications in Settings to try pocket cues.")
                            case .failed(let message): Text(message)
                            }
                            Button("Schedule cues") {
                                Task {
                                    await experiment.schedule(interval: interval, repetitions: repetitions)
                                }
                            }
                            .disabled(experiment.phase == .loading || experiment.phase == .requesting)
                            .accessibilityIdentifier("schedule-pocket-cues")
                            Button("End pocket cues") { Task { await experiment.cancel() } }
                                .accessibilityIdentifier("cancel-pocket-cues")
                        }
                    }
                    .navigationTitle("Pocket cues")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                    }
                    .task { await experiment.refresh() }
                    .onChange(of: scenePhase) { _, phase in
                        if phase == .active { Task { await experiment.refresh() } }
                    }
                }
            }
        }
    #endif
#endif
