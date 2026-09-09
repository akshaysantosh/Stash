import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var notificationRouter: NotificationRouter

    var body: some View {
        TabView {
            NavigationStack {
                LinksListView(isDone: false, title: "The Stash")
            }
            .tabItem { Label("The Stash", systemImage: "bookmark.fill") }

            NavigationStack {
                LinksListView(isDone: true, title: "Checked Out")
            }
            .tabItem { Label("Checked Out", systemImage: "checkmark.circle.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.accent)
        .sheet(item: Binding(
            get: { notificationRouter.pendingRecallTag.map(RecallTag.init) },
            set: { newValue in notificationRouter.pendingRecallTag = newValue?.tag }
        )) { wrapped in
            DailyRecallView(tag: wrapped.tag)
        }
    }
}

private struct RecallTag: Identifiable {
    let tag: String
    var id: String { tag }
}
