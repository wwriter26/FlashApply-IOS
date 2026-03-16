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
        AppLogger.network.debug("[\(method)] \(self.baseURL)\(endpoint) — fetching auth tokens")
        do {
            let idToken = try await AuthService.shared.getIdToken()
            #if DEBUG
            AppLogger.network.debug("Token (first 50 chars): \(String(idToken.prefix(50)))...")
            #endif
            return try await performRequest(
                endpoint: endpoint,
                method: method,
                body: body,
                headers: [
                    "Authorization": "Bearer \(idToken)",
                    "Content-Type": "application/json"
                ]
            )
        } catch let authErr as AuthError {
            AppLogger.network.error("[\(method)] \(endpoint) — auth token error: \(authErr.localizedDescription)")
            throw authErr
        }
    }

    // MARK: - Unauthenticated Request
    func unauthenticatedRequest<T: Decodable>(
        _ endpoint: String,
        method: String = "POST",
        body: Encodable? = nil
    ) async throws -> T {
        AppLogger.network.debug("[\(method)] \(self.baseURL)\(endpoint) — unauthenticated")
        return try await performRequest(
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
        AppLogger.network.debug("[GET] \(self.baseURL)\(endpoint) — params: \(params.keys.joined(separator: ", "))")
        do {
            let idToken = try await AuthService.shared.getIdToken()

            var components = URLComponents(string: baseURL + endpoint)
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let url = components?.url else {
                AppLogger.network.error("[GET] \(endpoint) — invalid URL after building query params")
                throw NetworkError.invalidURL
            }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            return try await execute(req)
        } catch let authErr as AuthError {
            AppLogger.network.error("[GET] \(endpoint) — auth token error: \(authErr.localizedDescription)")
            throw authErr
        }
    }

    // MARK: - Private Execute
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?,
        headers: [String: String]
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            AppLogger.network.error("[\(method)] \(self.baseURL)\(endpoint) — could not construct URL (check API_DOMAIN in Config.xcconfig)")
            throw NetworkError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }
        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try encoder.encode(body)
            #if DEBUG
            if let bodyData = req.httpBody, let bodyStr = String(data: bodyData, encoding: .utf8) {
                AppLogger.network.debug("Request body: \(bodyStr.prefix(500))")
            }
            #endif
        }
        #if DEBUG
        AppLogger.network.debug("[\(method)] \(url.absoluteString) — outgoing headers: \(headers.map { "\($0.key): \($0.key == "Authorization" ? String($0.value.prefix(40)) + "..." : $0.value)" }.joined(separator: ", "))")
        #endif
        return try await execute(req)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let fullURL = request.url?.absoluteString ?? "unknown"
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                AppLogger.network.error("[\(request.httpMethod ?? "GET")] \(fullURL) — response was not HTTP")
                throw NetworkError.noData
            }
            AppLogger.network.debug("[\(request.httpMethod ?? "GET")] \(fullURL) → \(http.statusCode)")

            switch http.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    return try decoder.decode(T.self, from: data)
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                    AppLogger.network.error("[\(request.httpMethod ?? "GET")] \(fullURL) — decode error: \(error) | raw: \(raw)")
                    throw NetworkError.decodingFailed(error)
                }
            case 401, 403:
                let body = String(data: data, encoding: .utf8) ?? ""
                AppLogger.network.error("[\(request.httpMethod ?? "GET")] \(fullURL) → \(http.statusCode) unauthorized — \(body)")
                throw NetworkError.unauthorized
            default:
                let message = String(data: data, encoding: .utf8)
                AppLogger.network.error("[\(request.httpMethod ?? "GET")] \(fullURL) → \(http.statusCode) — \(message ?? "no body")")
                throw NetworkError.serverError(http.statusCode, message)
            }
        } catch let urlError as URLError {
            AppLogger.network.error("[\(request.httpMethod ?? "GET")] \(fullURL) — connection error: \(urlError.localizedDescription) (code: \(urlError.code.rawValue))")
            throw urlError
        }
    }

    // MARK: - Multipart Upload (for resume / transcript)
    func uploadFile(
        to presignedURL: String,
        data: Data,
        mimeType: String
    ) async throws {
        guard let url = URL(string: presignedURL) else {
            AppLogger.files.error("[PUT] S3 upload — invalid presigned URL")
            throw NetworkError.invalidURL
        }
        AppLogger.files.debug("[PUT] S3 upload — \(data.count) bytes, mimeType: \(mimeType)")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data
        do {
            let (_, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                AppLogger.files.error("[PUT] S3 upload → \(statusCode) failed")
                throw NetworkError.serverError(statusCode, "Upload failed")
            }
            AppLogger.files.info("[PUT] S3 upload → \((response as? HTTPURLResponse)?.statusCode ?? 0) success")
        } catch let urlError as URLError {
            AppLogger.files.error("[PUT] S3 upload — connection error: \(urlError.localizedDescription)")
            throw urlError
        }
    }
}

// MARK: - Empty Response helper
struct EmptyResponse: Codable {}
struct MessageResponse: Codable {
    let message: String?
    let success: Bool?
}
