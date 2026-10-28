import UIKit

/// Three distinct haptic "signatures", so you can tell what happened without looking:
///
/// - **added**    — a bright rising double-tap (success buzz, then a soft pop): "got it".
/// - **deleted**  — one sharp, rigid tap and a light echo: short and final.
/// - **vaulted**  — a soft-medium-light cascade that tapers off, like something being set down in a box.
/// - **reopened** — a single light tap.
enum Haptics {
    static func added() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        after(0.16) { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8) }
    }

    static func deleted() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)
        after(0.09) { UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5) }
    }

    static func vaulted() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 1.0)
        after(0.08) { UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7) }
        after(0.18) { UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4) }
    }

    static func reopened() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    private static func after(_ seconds: Double, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }
}
