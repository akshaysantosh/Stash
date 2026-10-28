import SwiftUI

/// The pill that slides up above the tab bar. The icon bounces in with a ripple (and, for an
/// added link, a tiny burst of sparks); deleting and vaulting get their own icon and colour.
struct ToastView: View {
    let toast: Toast
    let onUndo: () -> Void
    @State private var go = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            icon
            Text(toast.message)
                .font(AppFont.rowTitle())
                .foregroundStyle(Color.ink)
                .lineLimit(1)
            if toast.undo != nil {
                Button("Undo", action: onUndo)
                    .font(AppFont.rowTitle())
                    .foregroundStyle(Color.accent)
                    .padding(.leading, AppSpacing.xs)
            }
        }
        .padding(.leading, AppSpacing.m)
        .padding(.trailing, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .background(Capsule().fill(Color.bgCard))
        .overlay(Capsule().stroke(Color.borderCard, lineWidth: 1))
        .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
        .onAppear { go = true }
        .accessibilityElement(children: .combine)
    }

    private var icon: some View {
        ZStack {
            if !reduceMotion {
                Circle()
                    .stroke(toast.tint.opacity(0.4), lineWidth: 2)
                    .frame(width: 26, height: 26)
                    .scaleEffect(go ? 2.0 : 0.8)
                    .opacity(go ? 0 : 1)
                    .animation(.easeOut(duration: 0.7), value: go)

                if toast.kind == .added {
                    ForEach(0..<6, id: \.self) { i in
                        Capsule()
                            .fill(i.isMultiple(of: 2) ? Color.accentSuccess : Color.accent)
                            .frame(width: 3, height: 7)
                            .offset(y: go ? -26 : -10)
                            .rotationEffect(.degrees(Double(i) * 60))
                            .opacity(go ? 0 : 1)
                            .scaleEffect(go ? 0.5 : 1)
                            .animation(.easeOut(duration: 0.6), value: go)
                    }
                }
            }
            Image(systemName: toast.icon)
                .font(.title3)
                .foregroundStyle(toast.tint)
                .symbolEffect(.bounce, options: .nonRepeating, value: go)
        }
        .frame(width: 30, height: 30)
    }
}

/// The toast itself, as a view to drop into a ZStack (so it sits above the content for touches too).
struct ToastLayer: View {
    @ObservedObject var center: ToastCenter

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            if let toast = center.current {
                ToastView(toast: toast) { center.undoCurrent() }
                    .id(toast.id)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
            }
        }
        // Only the toast itself should catch touches; the empty space around it must not block the list.
        .allowsHitTesting(center.current != nil)
    }
}

/// Hosts the toast above the tab bar. Applied on each screen that can trigger one (the list and the
/// link page) rather than on the TabView: an overlay on the TabView draws, but doesn't receive touches,
/// so Undo would fall through to the row underneath.
struct ToastHost: ViewModifier {
    @ObservedObject var center: ToastCenter

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast = center.current {
                ToastView(toast: toast) { center.undoCurrent() }
                    .id(toast.id)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
                    .onTapGesture { if toast.undo == nil { center.dismiss() } }
            }
        }
    }
}

extension View {
    func toastHost(_ center: ToastCenter) -> some View {
        modifier(ToastHost(center: center))
    }
}
