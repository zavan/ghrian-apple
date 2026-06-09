import Foundation

/// `GET /api/v1/inverters/:id/intraday` — downsampled chart series for a day.
/// `power` has one named series per element (PV/Grid/Load/Battery) in kW; `soc`
/// is a single series in percent.
public struct IntradaySeries: Codable, Sendable {
    public let inverterId: Int
    public let date: String
    public let power: [ChartSeries]
    public let soc: [ChartSeries]

    enum CodingKeys: String, CodingKey {
        case date, power, soc
        case inverterId = "inverter_id"
    }

    public var socSeries: ChartSeries? { soc.first }
}

public struct ChartSeries: Codable, Sendable, Identifiable {
    public let name: String
    public let data: [ChartPoint]

    public var id: String { name }
}

/// A `[recorded_at, value]` pair encoded as a JSON array.
public struct ChartPoint: Codable, Sendable, Identifiable {
    public let time: Date
    public let value: Double

    public var id: Date { time }

    public init(time: Date, value: Double) {
        self.time = time
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        self.time = try c.decode(Date.self)
        self.value = try c.decode(Double.self)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(time)
        try c.encode(value)
    }
}
