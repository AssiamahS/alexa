import Foundation

struct Alarm: Identifiable, Codable, Hashable {
    let id: String
    let type: String
    var status: String
    let date: String
    let time: String
    let label: String?
    let device: String
    let recurring: String?

    var isOn: Bool { status == "ON" }

    var displayTime: String {
        guard !time.isEmpty, let h24 = Int(time.prefix(2)) else { return "—" }
        let mins = String(time.suffix(2))
        let h12 = h24 % 12 == 0 ? 12 : h24 % 12
        return "\(h12):\(mins) \(h24 < 12 ? "AM" : "PM")"
    }
}

struct Device: Identifiable, Codable, Hashable {
    let name: String
    let serial: String
    var id: String { serial }
}

struct Health: Codable {
    let ok: Bool
    let reason: String?
    let devices: [String]?
}

enum APIError: LocalizedError {
    case server(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .badResponse: return "Bad response from the Mac"
        }
    }
}

struct AlarmAPI: Sendable {
    static let defaultBase = "http://saints-macbook-air.tail40af16.ts.net:8797"

    var base: String {
        UserDefaults.standard.string(forKey: "apiBase") ?? Self.defaultBase
    }

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: base + path) else { throw APIError.badResponse }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = method
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        if http.statusCode != 200 {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "HTTP \(http.statusCode)")
        }
        return data
    }

    func health() async throws -> Health {
        try JSONDecoder().decode(Health.self, from: try await request("/health"))
    }

    func alarms() async throws -> [Alarm] {
        try JSONDecoder().decode([Alarm].self, from: try await request("/alarms"))
    }

    func devices() async throws -> [Device] {
        try JSONDecoder().decode([Device].self, from: try await request("/devices"))
    }

    func toggle(id: String, on: Bool) async throws {
        _ = try await request("/alarms/toggle", method: "POST", body: ["id": id, "on": on])
    }

    func delete(id: String) async throws {
        _ = try await request("/alarms/delete", method: "POST", body: ["id": id])
    }

    func create(time: String, date: String?, device: String, label: String?, type: String) async throws {
        var body: [String: Any] = ["time": time, "device": device, "type": type]
        if let date { body["date"] = date }
        if let label, !label.isEmpty { body["label"] = label }
        _ = try await request("/alarms", method: "POST", body: body)
    }
}
