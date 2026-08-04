import SwiftUI

struct AddAlarmView: View {
    let store: AlarmStore

    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()
    @State private var day = "next"
    @State private var device = ""
    @State private var label = ""
    @State private var type = "Alarm"
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)

                Picker("Day", selection: $day) {
                    Text("Next occurrence").tag("next")
                    Text("Today").tag("today")
                    Text("Tomorrow").tag("tomorrow")
                }

                Picker("Device", selection: $device) {
                    ForEach(store.devices) { d in
                        Text(d.name).tag(d.name)
                    }
                }

                Picker("Type", selection: $type) {
                    Text("Alarm").tag("Alarm")
                    Text("Reminder").tag("Reminder")
                }
                .pickerStyle(.segmented)

                if type == "Reminder" {
                    TextField("What should Alexa say?", text: $label)
                } else {
                    TextField("Label (optional)", text: $label)
                }
            }
            .navigationTitle("New \(type)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        Task {
                            saving = true
                            let ok = await store.create(
                                time: time,
                                day: day == "next" ? nil : day,
                                device: device,
                                label: label,
                                type: type
                            )
                            saving = false
                            if ok { dismiss() }
                        }
                    }
                    .disabled(saving || device.isEmpty)
                }
            }
            .onAppear {
                if device.isEmpty { device = store.devices.first?.name ?? "" }
            }
        }
    }
}
