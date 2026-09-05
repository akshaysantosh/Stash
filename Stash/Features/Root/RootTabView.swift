import SwiftUI

struct RootTabView: View {
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
        }
        .tint(Color.accent)
    }
}
