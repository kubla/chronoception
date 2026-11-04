import ChronoceptionCore
import Foundation

@MainActor
final class PocketNotificationFixture: PocketNotificationService {
    var pending: Set<String> = []
    var pauseNextAdd = false
    var pausedAdd: CheckedContinuation<Void, Never>?
    var addStarted: CheckedContinuation<Void, Never>?
    var pauseNextRead = false
    var pausedRead: CheckedContinuation<Void, Never>?
    var readStarted: CheckedContinuation<Void, Never>?

    func authorize() async throws -> Bool { true }

    func pendingIdentifiers() async -> [String] {
        if pauseNextRead {
            pauseNextRead = false
            await withCheckedContinuation {
                pausedRead = $0
                readStarted?.resume()
                readStarted = nil
            }
        }
        return Array(pending)
    }

    func add(identifier: String, body: String, delay: Double) async throws {
        if pauseNextAdd {
            pauseNextAdd = false
            await withCheckedContinuation {
                pausedAdd = $0
                addStarted?.resume()
                addStarted = nil
            }
        }
        pending.insert(identifier)
    }

    func remove(identifiers: [String]) { pending.subtract(identifiers) }

    func waitForAdd() async {
        if pausedAdd != nil { return }
        await withCheckedContinuation { addStarted = $0 }
    }

    func waitForRead() async {
        if pausedRead != nil { return }
        await withCheckedContinuation { readStarted = $0 }
    }
}

@MainActor
struct PocketCueTests {
    static func run() async {
        let interval = PracticeInterval.fiveMinutes
        let fixture = PocketNotificationFixture()
        let experiment = PocketCueExperiment(service: fixture)
        fixture.pending = ["chronoception.pocket.existing", "unrelated"]
        fixture.pauseNextRead = true
        let initialRefresh = Task { await experiment.refresh() }
        await fixture.waitForRead()
        await experiment.cancel()
        fixture.pausedRead?.resume()
        await initialRefresh.value
        precondition(
            fixture.pending == ["unrelated"], "End must cancel unobserved system requests after reopen")
        precondition(experiment.phase == .ready)

        fixture.pauseNextAdd = true
        let oldPreparation = Task { await experiment.schedule(interval: interval, repetitions: 3) }
        await fixture.waitForAdd()
        await experiment.cancel()
        fixture.pausedAdd?.resume()
        fixture.pausedAdd = nil
        await oldPreparation.value
        precondition(fixture.pending == ["unrelated"], "Cancelled preparation must remove its late request")

        fixture.pauseNextAdd = true
        let replacedPreparation = Task { await experiment.schedule(interval: interval, repetitions: 3) }
        await fixture.waitForAdd()
        await experiment.schedule(interval: interval, repetitions: 1)
        let replacement = fixture.pending
        precondition(replacement.count == 2)
        fixture.pausedAdd?.resume()
        fixture.pausedAdd = nil
        await replacedPreparation.value
        precondition(fixture.pending == replacement, "Old preparation must not change replacement cues")
        precondition(experiment.phase == .scheduled(1))
        await experiment.cancel()
        precondition(fixture.pending == ["unrelated"])
        print(
            "PASS: pocket cancellation reconciles the system queue, removes late requests and preserves replacement cues."
        )
    }
}
