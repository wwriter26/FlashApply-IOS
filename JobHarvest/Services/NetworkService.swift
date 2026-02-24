import Foundation
import os

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case decodingFailed(Error)
    case serverError(Int, String?)
    case unauthorized
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid URL."
        case .decodingFailed(let e):   return "Data parse error: \(e.localizedDescription)"
        case .serverError(let c, let m): return m ?? "Server error (\(c))."
        case .unauthorized:            return "Session expired. Please sign in again."
        case .noData:                  return "No data received."
        }
    }
}

// MARK: - NetworkService
final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    private var baseURL: String { AppConfig.apiDomain }

    // MARK: - Authenticated Request
    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        let idToken = try await AuthService.shared.getIdToken()
        let identityId = try await AuthService.shared.getIdentityId()
        return try await performRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: [
                "Authorization": "Bearer \(idToken)",
                "X-Cognito-Identity-Id": identityId,
                "Content-Type": "application/json"
            ]
        )
    }

    // MARK: - Unauthenticated Request
    func unauthenticatedRequest<T: Decodable>(
        _ endpoint: String,
        method: String = "POST",
        body: Encodable? = nil
    ) async throws -> T {
        try await performRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: ["Content-Type": "application/json"]
        )
    }

    // MARK: - Request with Query Params
    func requestWithParams<T: Decodable>(
        _ endpoint: String,
        params: [String: String]
    ) async throws -> T {
        let idToken = try await AuthService.shared.getIdToken()
        let identityId = try await AuthService.shared.getIdentityId()

        var components = URLComponents(string: baseURL + endpoint)
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        req.setValue(identityId, forHTTPHeaderField: "X-Cognito-Identity-Id")

        return try await execute(req)
    }

    // MARK: - Private Execute
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?,
        headers: [String: String]
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        if let body = body {
            req.httpBody = try JSONEncoder().encode(body)
        }
        return try await execute(req)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        AppLogger.network.debug("[\(request.httpMethod ?? "GET")] \(request.url?.path ?? "") → \(http.statusCode)")

        switch http.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                AppLogger.network.error("Decode error: \(error)")
                throw NetworkError.decodingFailed(error)
            }
        case 401, 403:
            throw NetworkError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(http.statusCode, message)
        }
    }

    // MARK: - Multipart Upload (for resume / transcript)
    func uploadFile(
        to presignedURL: String,
        data: Data,
        mimeType: String
    ) async throws {
        guard let url = URL(string: presignedURL) else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0, "Upload failed")
        }
    }
}

// MARK: - Empty Response helper
struct EmptyResponse: Codable {}
struct MessageResponse: Codable {
    let message: String?
    let success: Bool?
}
