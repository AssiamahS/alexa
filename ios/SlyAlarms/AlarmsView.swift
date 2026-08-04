import SwiftUI

struct AlarmsView: View {
    @State private var store = AlarmStore()
    @State private var showAdd = false

    private var upcoming: [Alarm] {
        store.alarms.filter { $0.isOn }
    }

    private var rest: [Alarm] {
        store.alarms.filter { !$0.isOn }
    }

    var body: some View {
        NavigationStack {
            List {
                if !store.connected, let message = store.errorMessage {
                    Section {
                        Label(message, systemImage: "wifi.exclamationmark")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                }
                if !upcoming.isEmpty {
                    Section("On") {
                        ForEach(upcoming) { alarm in row(alarm) }
                    }
                }
                Section(upcoming.isEmpty ? "Alarms" : "Off") {
                    if rest.isEmpty && upcoming.isEmpty && !store.loading {
                        Text("No alarms")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(rest) { alarm in row(alarm) }
                }
            }
            .navigationTitle("SlyAlarms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable { await store.refresh() }
            .sheet(isPresented: $showAdd) {
                AddAlarmView(store: store)
            }
            .task { await store.refresh() }
        }
    }

    @ViewBuilder
    private func row(_ alarm: Alarm) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(alarm.displayTime)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(alarm.isOn ? .primary : .secondary)
                HStack(spacing: 4) {
                    if alarm.type != "Alarm" {
                        Text(alarm.type)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.tint.opacity(0.15), in: Capsule())
                    }
                    Text(alarm.label ?? alarm.device)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(alarm.date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { alarm.isOn },
                set: { on in Task { await store.toggle(alarm, on: on) } }
            ))
            .labelsHidden()
        }
        .swipeActions {
            Button(role: .destructive) {
                Task { await store.delete(alarm) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    AlarmsView()
}
