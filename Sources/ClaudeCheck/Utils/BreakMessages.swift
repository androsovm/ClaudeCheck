import Foundation

/// Playful English copy shown when services go down. Picked at random in
/// the menu headline and in notifications.
enum BreakMessages {
    static let down: [String] = [
        "Claude Code is down — you're allowed to live a little.",
        "No autocomplete. Time to remember how to code.",
        "Rubber duck debugging is back on the menu 🦆",
        "Go review that PR you've been ignoring.",
        "Read the docs you kept telling it to read.",
        "`git blame` yourself for once.",
        "Stack Overflow still works. We're not animals.",
        "503 Service Unavailable → 200 Human Break OK",
        "Refactor something you understand.",
        "Vim users unaffected. Everyone else: stretch.",
        "Pair program with a human. Remember those?",
        "The models are down. Your brain isn't.",
        "Write a real comment. Not a TODO.",
        "Close the laptop. Open a terminal on the stove ☕",
        "Ship human thoughts for a change."
    ]

    static let recovery: [String] = [
        "Claude Code is back. Resume the vibes.",
        "Autocomplete restored. PRs incoming.",
        "Models warmed up. `git push` away.",
        "The AI pair is back at the keyboard.",
        "Back online. Back to shipping."
    ]

    static func randomDown() -> String {
        down.randomElement() ?? "Claude is down. Take a break."
    }

    static func randomRecovery() -> String {
        recovery.randomElement() ?? "Claude is back."
    }
}
