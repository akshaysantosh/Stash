import SwiftUI
import SwiftData
import UIKit

@main
struct StashApp: App {
    let modelContainer: ModelContainer = {
        let schema = Schema([SavedLink.self])
        let configuration: ModelConfiguration
        if let groupURL = AppGroup.containerURL {
            // Shared with the Share Extension, so links saved from the share sheet show up here.
            configuration = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("Stash.sqlite"), cloudKitDatabase: .none)
        } else {
            // App Group entitlement isn't actually provisioned (e.g. a free Apple ID account) —
            // fall back to the app's own local storage rather than crash. The Share Extension
            // won't be able to see this data in that case, but the main app keeps working.
            configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.bgPage)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.ink)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.ink)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.bgCard)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.light)
                .tint(Color.accent)
        }
        .modelContainer(modelContainer)
    }
}
