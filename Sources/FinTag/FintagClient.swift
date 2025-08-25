import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import CryptoSwift
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class FinTagClient {
    private let apiKey: String
    private let baseURL: String

    public init(apiKey: String, baseURL: String = "<API_BASE_URL>") {
        self.apiKey = apiKey
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    // MARK: - Signature
    private func makeSignature(timestamp: String) -> String {
        #if canImport(CryptoKit)
        let key = SymmetricKey(data: Data(apiKey.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(timestamp.utf8), using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
        #else
        let hmac = try! HMAC(key: apiKey.bytes, variant: .sha256).authenticate(timestamp.bytes)
        return hmac.toHexString()
        #endif
    }

    private func getHeaders() -> [String: String] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signatureHex = makeSignature(timestamp: timestamp)

        return [
            "authorization": apiKey,
            "x-timestamp": timestamp,
            "x-signature": signatureHex
        ]
    }

    // MARK: - Request
    private func request(endpoint: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        getHeaders().forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "InvalidJSON", code: -1)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    // MARK: - Public API
    public func verify(fintag: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let cleaned = fintag.hasPrefix("#") ? String(fintag.dropFirst()) : fintag
        request(endpoint: "/fintag/verify/\(cleaned)", completion: completion)
    }

    public func getWalletInfo(fintag: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let cleaned = fintag.hasPrefix("#") ? String(fintag.dropFirst()) : fintag
        request(endpoint: "/fintag/wallet/\(cleaned)", completion: completion)
    }
}
