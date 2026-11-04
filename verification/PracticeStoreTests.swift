import ChronoceptionCore
import ChronoceptionStorage
import Foundation

@main
struct PracticeStoreTests {
    @MainActor
    static func main() async throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        for index in 0..<10 {
            let store = PracticeStore(directory: root.appending(path: "race-\(index)"))
            store.beginTraining()
            let oldRunner = Task { await store.runTraining() }
            try await Task.sleep(for: .milliseconds(10))
            store.cancelTraining()
            store.resetTraining()
            oldRunner.cancel()
            store.beginTraining()
            await oldRunner.value
            guard case .training = store.training.phase else {
                fatalError("Cancelling the old runner interrupted its replacement")
            }
            store.cancelTraining()
        }
        let directory = root.appending(path: "storage-retry")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: "history.json")
        try Data("broken history".utf8).write(to: file)
        let store = PracticeStore(directory: directory)
        precondition(store.storageMessage != nil)
        store.beginTraining()
        store.cancelTraining()
        precondition(store.history.trainingRecords.count == 1)
        try FileManager.default.removeItem(at: file)
        store.retryStorage()
        precondition(store.storageMessage == nil)
        let reloaded = PracticeStore(directory: directory)
        precondition(reloaded.history.trainingRecords.count == 1)
        precondition(reloaded.history.trainingRecords[0].status == .cancelled)
        print(
            "PASS: old-runner cancellation preserves replacement training; training-only retry survives relaunch."
        )
    }
}
