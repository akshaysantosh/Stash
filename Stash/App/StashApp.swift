import SwiftUI
import SwiftData
import UIKit
import UserNotifications

@main
struct StashApp: App {
    let modelContainer: ModelContainer = {
        #if DEBUG
        if CommandLine.arguments.contains("-seedSampleData") {
            return SampleData.makeContainer()
        }
        #endif
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
        // Navigation and tab bars use the system appearance (large titles, liquid glass on newer
        // iOS); the cream background comes from each screen's own `.background(Color.bgPage)`.
        // Daily recall was removed. Clean up anything it left behind on devices that had it on.
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["com.akshay.stash.dailyRecall"])
        for key in ["dailyRecallEnabled", "dailyRecallTag", "dailyRecallHour", "dailyRecallMinute"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
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
