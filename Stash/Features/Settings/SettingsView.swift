import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var links: [SavedLink]
    @AppStorage("dailyRecallEnabled") private var enabled = false
    @AppStorage("dailyRecallTag") private var selectedTag = ""
    @AppStorage("dailyRecallHour") private var hour = 9
    @AppStorage("dailyRecallMinute") private var minute = 0
    @Environment(\.dismiss) private var dismiss
    @State private var authorizationDenied = false

    private var allTags: [String] {
        Set(links.flatMap(\.tags)).sorted()
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date() },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour = components.hour ?? 9
                minute = components.minute ?? 0
                rescheduleIfNeeded()
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                Text("Get a daily nudge to revisit something you saved under a specific tag — it helps it actually stick.")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)

                if allTags.isEmpty {
                    CalloutBanner(text: "Tag a saved link first (open it → ⋯ → Edit → Tags), then pick a tag here.")
                } else {
                    CardView {
                        Toggle("Daily recall", isOn: Binding(
                            get: { enabled },
                            set: { newValue in
                                enabled = newValue
                                if newValue {
                                    Task { await enableRecall() }
                                } else {
                                    NotificationScheduler.cancel()
                                }
                            }
                        ))
                        .tint(Color.accent)

                        if enabled {
                            Divider().padding(.vertical, AppSpacing.xs)

                            Picker("Tag", selection: Binding(
                                get: { selectedTag.isEmpty ? (allTags.first ?? "") : selectedTag },
                                set: { newValue in
                                    selectedTag = newValue
                                    rescheduleIfNeeded()
                                }
                            )) {
                                ForEach(allTags, id: \.self) { tag in
                                    Text(tag.asTag).tag(tag)
                                }
                            }

                            DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                        }
                    }

                    if enabled && authorizationDenied {
                        CalloutBanner(
                            text: "Notifications are off for Stash. Enable them in iOS Settings to get your daily recall.",
                            style: .warn
                        )
                    }
                }
            }
            .padding(AppSpacing.l)
        }
        .background(Color.bgPage)
        .navigationTitle("Daily recall")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func enableRecall() async {
        let granted = await NotificationScheduler.requestAuthorization()
        authorizationDenied = !granted
        guard granted else {
            enabled = false
            return
        }
        if selectedTag.isEmpty { selectedTag = allTags.first ?? "" }
        NotificationScheduler.schedule(tag: selectedTag, hour: hour, minute: minute)
    }

    private func rescheduleIfNeeded() {
        guard enabled, !selectedTag.isEmpty else { return }
        NotificationScheduler.schedule(tag: selectedTag, hour: hour, minute: minute)
    }
}
