import Foundation
import SwiftParser
import SwiftSyntax

struct Finding: Equatable {
    let rule: String
    let message: String
}

final class CoreVisitor: SyntaxVisitor {
    var findings: [Finding] = []

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        let module = node.path.map { $0.name.text }.joined(separator: ".")
        if module != "Foundation" {
            findings.append(
                Finding(
                    rule: "CORE-IMPORT",
                    message:
                        "The deterministic core imports \(module). Put platform effects at their boundary."))
        }
        return .skipChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        let platformNames: Set<String> = [
            "FileManager", "URLSession", "ProcessInfo", "UserDefaults", "ContinuousClock", "SuspendingClock",
            "Timer",
        ]
        if platformNames.contains(node.baseName.text) {
            findings.append(
                Finding(
                    rule: "CORE-EFFECT",
                    message: "Pass explicit input to the core instead of using \(node.baseName.text)."))
        }
        return .visitChildren
    }
}

func inspect(_ source: String, core: Bool) -> [Finding] {
    let syntax = Parser.parse(source: source)
    var findings: [Finding] = []
    for token in syntax.tokens(viewMode: .sourceAccurate) {
        for piece in token.leadingTrivia + token.trailingTrivia {
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                findings.append(
                    Finding(
                        rule: "CLEAR-CODE",
                        message:
                            "Put explanations in domain/state artifacts and express local intent in names and tests."
                    ))
            default: break
            }
        }
    }
    if core {
        let visitor = CoreVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntax)
        findings += visitor.findings
    }
    return findings
}

if CommandLine.arguments.contains("--self-test") {
    let fixtures: [(String, String, Bool, Set<String>)] = [
        ("domain value", "import Foundation\nstruct Interval { let seconds: Int }", true, []),
        ("URL string", "let help = \"https://example.com\"", false, []),
        ("comment-like string", "let sample = \"/* literal, not commentary */\"", false, []),
        ("line comment", "// repeats code\nlet count = 1", false, ["CLEAR-CODE"]),
        ("doc comment", "/// counts\nlet count = 1", false, ["CLEAR-CODE"]),
        ("platform import", "import SwiftUI", true, ["CORE-IMPORT"]),
        ("hidden Foundation effect", "let files = FileManager.default", true, ["CORE-EFFECT"]),
        ("platform adapter", "import Foundation\nlet files = FileManager.default", false, []),
        (
            "explicit timing", "func elapsed(start: Duration, end: Duration) -> Duration { end - start }",
            true, []
        ),
        ("injected wall-date value", "import Foundation\nstruct Record { let startedAt: Date }", true, []),
    ]
    for (name, source, core, expected) in fixtures {
        let actual = Set(inspect(source, core: core).map(\.rule))
        guard actual == expected else {
            print("FAIL \(name): expected \(expected), got \(actual)")
            exit(1)
        }
    }
    print(
        "PASS: \(fixtures.count) parser-based rule fixtures, including accepted comment-like strings and platform adapters."
    )
} else {
    let root = URL(fileURLWithPath: CommandLine.arguments[1])
    var count = 0
    var failures = 0
    for folder in ["Application", "Shared/Sources"] {
        let directory = root.appending(path: folder)
        let paths = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)!
        for case let url as URL in paths where url.pathExtension == "swift" {
            count += 1
            let source = try String(contentsOf: url, encoding: .utf8)
            let findings = inspect(source, core: url.path.contains("/ChronoceptionCore/"))
            for finding in findings {
                failures += 1
                print("\(url.path): \(finding.rule): \(finding.message)")
            }
        }
    }
    print("Inspected \(count) product Swift files; \(failures) findings.")
    if failures > 0 { exit(1) }
}
