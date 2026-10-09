import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LinksListView(isDone: false, title: "The Stash")
            }
            .tabItem { Label("The Stash", systemImage: "bookmark.fill") }

            NavigationStack {
                LinksListView(isDone: true, title: "Vault")
            }
            .tabItem { Label("Vault", systemImage: "archivebox.fill") }
        }
        .tint(Color.accent)
    }
}
