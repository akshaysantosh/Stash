import SwiftUI

/// A short message that confirms what just happened, with an optional Undo.
struct Toast: Identifiable {
    enum Kind { case added, deleted, vaulted, reopened }

    let id = UUID()
    let kind: Kind
    let message: String
    var undo: (() -> Void)?

    var icon: String {
        switch kind {
        case .added: return "checkmark.circle.fill"
        case .deleted: return "trash.fill"
        case .vaulted: return "archivebox.fill"
        case .reopened: return "arrow.uturn.backward.circle.fill"
        }
    }

    var tint: Color {
        switch kind {
        case .added: return .accentSuccess
        case .deleted: return .calloutWarnText
        case .vaulted: return .accent
        case .reopened: return .textSecondary
        }
    }
}

/// One toast at a time, shown above the tab bar by `RootTabView`. Also tells the list which row
/// to flash after adding a link.
@MainActor
final class ToastCenter: ObservableObject {
    @Published private(set) var current: Toast?
    @Published private(set) var highlightedID: UUID?

    /// Debug builds can stretch toast/highlight lifetimes (launch with `-slowFeedback`) so they can be
    /// inspected in screenshots; release builds always use 1.
    private static let lifetimeScale: Double = {
        #if DEBUG
        CommandLine.arguments.contains("-slowFeedback") ? 5 : 1
        #else
        1
        #endif
    }()

    private var dismissTask: Task<Void, Never>?
    private var highlightTask: Task<Void, Never>?

    /// `delay` lets a toast wait for a sheet to finish dismissing before it appears.
    func show(_ toast: Toast, after delay: TimeInterval = 0) {
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled, let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { self.current = toast }
            try? await Task.sleep(for: .seconds((toast.undo == nil ? 2.4 : 4.2) * Self.lifetimeScale))
            guard !Task.isCancelled else { return }
            self.dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.22)) { current = nil }
    }

    func undoCurrent() {
        guard let toast = current else { return }
        toast.undo?()
        dismiss()
    }

    /// Flashes (and scrolls to) a row, e.g. the link that was just added.
    func highlight(_ id: UUID, after delay: TimeInterval = 0) {
        highlightTask?.cancel()
        highlightTask = Task { [weak self] in
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled, let self else { return }
            self.highlightedID = id
            try? await Task.sleep(for: .seconds(2.0 * Self.lifetimeScale))
            guard !Task.isCancelled else { return }
            self.highlightedID = nil
        }
    }
}
