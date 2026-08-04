import Foundation
import Observation

@MainActor
@Observable
final class AlarmStore {
    var alarms: [Alarm] = []
    var devices: [Device] = []
    var connected = false
    var errorMessage: String?
    var loading = false

    private let api = AlarmAPI()

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            async let alarmsTask = api.alarms()
            async let devicesTask = api.devices()
            alarms = try await alarmsTask
            devices = try await devicesTask
            connected = true
            errorMessage = nil
        } catch {
            connected = false
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ alarm: Alarm, on: Bool) async {
        guard let idx = alarms.firstIndex(of: alarm) else { return }
        alarms[idx].status = on ? "ON" : "OFF" // optimistic; revert on failure
        do {
            try await api.toggle(id: alarm.id, on: on)
        } catch {
            alarms[idx].status = on ? "OFF" : "ON"
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ alarm: Alarm) async {
        do {
            try await api.delete(id: alarm.id)
            alarms.removeAll { $0.id == alarm.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(time: Date, day: String?, device: String, label: String, type: String) async -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        do {
            try await api.create(
                time: formatter.string(from: time),
                date: day,
                device: device,
                label: label,
                type: type
            )
            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
