import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var links: [SavedLink]
    @AppStorage("dailyRecallEnabled") private var enabled = false
    @AppStorage("dailyRecallTag") private var selectedTag = ""
    @AppStorage("dailyRecallHour") private var hour = 9
    @AppStorage("dailyRecallMinute") private var minute = 0
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
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                PageHeader(title: "Settings")

                CardView {
                    SectionLabel(text: "Daily recall")
                    Text("Get a daily nudge to revisit something you saved under a specific tag — helps it actually stick.")
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 4)

                    if allTags.isEmpty {
                        Text("Tag a saved link first (open it → pencil icon → Tags) — then you can pick a tag here.")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textMuted)
                            .padding(.top, 8)
                    } else {
                        Toggle("Enable daily recall", isOn: Binding(
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
                        .padding(.top, 12)

                        if enabled {
                            Picker("Tag", selection: Binding(
                                get: { selectedTag.isEmpty ? (allTags.first ?? "") : selectedTag },
                                set: { newValue in
                                    selectedTag = newValue
                                    rescheduleIfNeeded()
                                }
                            )) {
                                ForEach(allTags, id: \.self) { tag in
                                    Text("#\(tag)").tag(tag)
                                }
                            }
                            .padding(.top, 8)

                            DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                                .padding(.top, 4)

                            if authorizationDenied {
                                CalloutBanner(
                                    text: "Notifications are off for Stash. Enable them in iOS Settings to get your daily recall.",
                                    style: .warn
                                )
                                .padding(.top, 8)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
