import Foundation

public enum APIError: Error, Sendable, Equatable, LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case http(Int)
    case decoding(String)
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: "The server URL is invalid."
        case .unauthorized: "Invalid or expired API token."
        case .notFound: "Not found."
        case .http(let code): "Server returned HTTP \(code)."
        case .decoding(let message): "Couldn't read the server response: \(message)"
        case .transport(let message): "Couldn't reach the server: \(message)"
        }
    }
}
