import Foundation

/// A solar inverter as returned by `GET /api/v1/inverters[/:id]`. Carries the raw
/// `latestValues` plus a server-computed `snapshot` (power flow + today's energy)
/// so clients never reimplement the sign/direction conventions.
public struct Inverter: Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let deviceModel: String?
    public let mqttTopic: String
    public let serialNumber: String?
    public let status: InverterStatus
    public let lastReadingAt: Date?
    public let lastSeenAt: Date?
    public let latestValues: [String: MetricValue]
    public let snapshot: InverterSnapshot

    enum CodingKeys: String, CodingKey {
        case id, name, status, snapshot
        case deviceModel = "device_model"
        case mqttTopic = "mqtt_topic"
        case serialNumber = "serial_number"
        case lastReadingAt = "last_reading_at"
        case lastSeenAt = "last_seen_at"
        case latestValues = "latest_values"
    }
}

public enum InverterStatus: String, Codable, Sendable {
    case online, offline, unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = InverterStatus(rawValue: raw) ?? .unknown
    }
}

// Response envelopes.
struct InvertersResponse: Decodable { let inverters: [Inverter] }
struct InverterResponse: Decodable { let inverter: Inverter }
