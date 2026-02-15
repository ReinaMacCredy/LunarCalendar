import SwiftUI

struct SourcesSettingsTab: View {
    @Bindable var model: AppState

    private var eventSources: [CalendarSource] {
        model.availableSources.filter { $0.kind == .event }
    }

    private var reminderSources: [CalendarSource] {
        model.availableSources.filter { $0.kind == .reminder }
    }

    var body: some View {
        Form {
            if eventSources.isEmpty && reminderSources.isEmpty {
                Section {
                    Text("No sources available yet. Grant Calendar and Reminders access first.")
                        .foregroundStyle(.secondary)
                }
            }

            if !eventSources.isEmpty {
                Section("Event Calendars") {
                    Toggle("Use All Event Calendars", isOn: $model.settings.allEventCalendarsSelected)

                    if !model.settings.allEventCalendarsSelected {
                        ForEach(eventSources) { source in
                            Toggle(
                                source.title,
                                isOn: Binding(
                                    get: { model.isSourceSelected(source) },
                                    set: { model.setSource(source, isSelected: $0) }
                                )
                            )
                        }
                    }
                }
                .animation(.default, value: model.settings.allEventCalendarsSelected)
            }

            if !reminderSources.isEmpty {
                Section("Reminder Lists") {
                    Toggle("Use All Reminder Lists", isOn: $model.settings.allReminderCalendarsSelected)

                    if !model.settings.allReminderCalendarsSelected {
                        ForEach(reminderSources) { source in
                            Toggle(
                                source.title,
                                isOn: Binding(
                                    get: { model.isSourceSelected(source) },
                                    set: { model.setSource(source, isSelected: $0) }
                                )
                            )
                        }
                    }
                }
                .animation(.default, value: model.settings.allReminderCalendarsSelected)
            }
        }
        .formStyle(.grouped)
    }
}
