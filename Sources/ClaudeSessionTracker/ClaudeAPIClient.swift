import Foundation

/// Talks to claude.ai's own (private, undocumented) usage endpoint — the
/// same one the Settings > Usage panel in the web app calls. Authenticated
/// using the session cookie captured during sign-in. Since this isn't a
/// public API, Anthropic could change or remove it at any time.
enum ClaudeAPIClient {
    enum APIError: Error, CustomStringConvertible {
        case notSignedIn
        case httpError(Int)
        case noOrganization
        case decodingFailed(String)

        var description: String {
            switch self {
            case .notSignedIn: return "Not signed in to claude.ai."
            case .httpError(let code): return "claude.ai returned an error (HTTP \(code)). Your session may have expired — try signing in again."
            case .noOrganization: return "No organization found on this account."
            case .decodingFailed(let detail): return "Couldn't read claude.ai's response (the API may have changed). \(detail)"
            }
        }
    }

    private static let baseURL = URL(string: "https://claude.ai/api")!

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]

        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            let str = try container.decode(String.self)
            if let d = withFraction.date(from: str) { return d }
            if let d = plain.date(from: str) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date: \(str)")
        }
        return decoder
    }

    private static func request(path: String, cookie: String) -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.setValue(cookie, forHTTPHeaderField: "Cookie")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        req.setValue("https://claude.ai/", forHTTPHeaderField: "Referer")
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        req.cachePolicy = .reloadIgnoringLocalCacheData
        return req
    }

    static func fetchOrganizationId(cookie: String) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request(path: "organizations", cookie: cookie))
        guard let http = response as? HTTPURLResponse else { throw APIError.decodingFailed("No HTTP response.") }
        guard http.statusCode == 200 else { throw APIError.httpError(http.statusCode) }

        do {
            let orgs = try JSONDecoder().decode([Organization].self, from: data)
            guard let first = orgs.first else { throw APIError.noOrganization }
            return first.uuid
        } catch let error as APIError {
            throw error
        } catch {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? "<binary>"
            throw APIError.decodingFailed("organizations: \(snippet)")
        }
    }

    static func fetchUsage(organizationId: String, cookie: String) async throws -> UsageResponse {
        let (data, response) = try await URLSession.shared.data(
            for: request(path: "organizations/\(organizationId)/usage", cookie: cookie)
        )
        guard let http = response as? HTTPURLResponse else { throw APIError.decodingFailed("No HTTP response.") }
        guard http.statusCode == 200 else { throw APIError.httpError(http.statusCode) }

        do {
            return try makeDecoder().decode(UsageResponse.self, from: data)
        } catch {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? "<binary>"
            throw APIError.decodingFailed("usage: \(snippet)")
        }
    }
}
