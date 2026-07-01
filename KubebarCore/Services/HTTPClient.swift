import Foundation

/// Injectable HTTP client boundary for AI provider requests.
///
/// Production access wraps `URLSession`; tests inspect the constructed
/// `URLRequest` without real network calls.
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
