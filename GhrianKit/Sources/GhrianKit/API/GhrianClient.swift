import Foundation

/// Async client for the ghrian token-authenticated REST API. Value type so it's
/// trivially `Sendable`; inject a custom `URLSession` (e.g. an ephemeral one with a
/// `URLProtocol` stub) for tests.
public struct GhrianClient: Sendable {
    public let baseURL: URL
    public let token: String
    private let session: URLSession

    public init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    // MARK: Endpoints

    public func inverters() async throws -> [Inverter] {
        try await get("api/v1/inverters", type: InvertersResponse.self).inverters
    }

    public func inverter(id: Int) async throws -> Inverter {
        try await get("api/v1/inverters/\(id)", type: InverterResponse.self).inverter
    }

    public func intraday(inverterID: Int, date: Date? = nil) async throws -> IntradaySeries {
        var query: [URLQueryItem] = []
        if let date { query.append(URLQueryItem(name: "date", value: GhrianDate.dayString(date))) }
        return try await get("api/v1/inverters/\(inverterID)/intraday", query: query, type: IntradaySeries.self)
    }

    public func energy(inverterID: Int?, period: EnergyPeriod, date: Date? = nil) async throws -> EnergyReport {
        var query = [URLQueryItem(name: "period", value: period.rawValue)]
        if let date { query.append(URLQueryItem(name: "date", value: GhrianDate.dayString(date))) }
        let path = inverterID.map { "api/v1/inverters/\($0)/energy" } ?? "api/v1/energy"
        return try await get(path, query: query, type: EnergyReport.self)
    }

    // MARK: Plumbing

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = GhrianDate.parse(string) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Unrecognized date: \(string)")
                )
            }
            return date
        }
        return decoder
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = [], type: T.Type) async throws -> T {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport("Not an HTTP response.")
        }
        switch http.statusCode {
        case 200..<300: break
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        default: throw APIError.http(http.statusCode)
        }

        do {
            return try Self.makeDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }
}
