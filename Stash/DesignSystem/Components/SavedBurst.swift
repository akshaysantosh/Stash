import SwiftUI

/// A small celebration: a check mark that draws itself inside a filled circle, a ring that
/// ripples outward, and a ring of sparks that fly off. Used on the Share Extension's "Stashed"
/// moment and (smaller) in the in-app toast. Falls back to a still check mark for Reduce Motion.
struct SavedBurst: View {
    var size: CGFloat = 84
    var tint: Color = .accentSuccess
    @State private var go = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let sparks = 8

    var body: some View {
        ZStack {
            if !reduceMotion {
                Circle()
                    .stroke(tint.opacity(0.45), lineWidth: max(2, size * 0.03))
                    .frame(width: size, height: size)
                    .scaleEffect(go ? 1.9 : 0.9)
                    .opacity(go ? 0 : 1)

                ForEach(0..<sparks, id: \.self) { i in
                    let angle = Double(i) / Double(sparks) * .pi * 2
                    Capsule()
                        .fill(i.isMultiple(of: 2) ? tint : Color.accent)
                        .frame(width: size * 0.05, height: size * 0.13)
                        .offset(y: -(go ? size * 0.95 : size * 0.5))
                        .rotationEffect(.radians(angle))
                        .scaleEffect(go ? 0.4 : 1)
                        .opacity(go ? 0 : 1)
                }
            }

            Circle()
                .fill(tint)
                .frame(width: size, height: size)
                .scaleEffect(go ? 1 : 0.4)

            CheckShape()
                .trim(from: 0, to: go ? 1 : 0)
                .stroke(Color.bgCard, style: StrokeStyle(lineWidth: size * 0.085, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.42, height: size * 0.32)
        }
        .frame(width: size * 2.2, height: size * 2.2)
        .onAppear {
            if reduceMotion {
                go = true
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) { go = true }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        p.addLine(to: CGPoint(x: rect.width * 0.36, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
