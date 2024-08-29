import Foundation

protocol NetworkRequest {
    associatedtype ReturnType: Codable

    var path: String { get }
    var method: HTTPMethod { get }
    var contentType: String { get }
    var client: String { get }
    var queryItems: [String: Any]? { get }
    var body: [String: Any]? { get }
    var headers: [String: String] { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Default Values
extension NetworkRequest {
    var method: HTTPMethod { .get }
    var contentType: String { "application/json" }
    var client: String { "ios" }
    var queryItems: [String: Any]? { nil }
    var body: [String: Any]? { nil }
    var headers: [String: String] { ["contentType": self.contentType, "client": self.client] }
}

// MARK: - Utility Methods
extension NetworkRequest {
    /// Transforms a URL into a URL Request Object,.
    // TODO: check if `baseURL` should be an URL or a String
    func toURLRequest(_ baseURL: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: baseURL) else { return nil }
        urlComponents.path = "\(urlComponents.path)\(self.path)"
        urlComponents.queryItems = self.requestQueryItemsFrom(queryItems)
        guard let url = urlComponents.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = self.method.rawValue
        request.httpBody = self.requestHTTPBodyFrom(body)
        request.allHTTPHeaderFields = self.headers
        return request
    }

    /// Serializes an HTTP dictionary to a JSON Data Object
    private func requestHTTPBodyFrom(_ params: [String: Any]?) -> Data? {
        guard let params = params, let httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        else { return nil }

        return httpBody
    }

    private func requestQueryItemsFrom(_  params: [String: Any]?) -> [URLQueryItem]? {
        guard let params = params else { return nil }
        return params.map { item in
            let value = if let val = item.value as? String {
                val
            } else {
                "\(item.value)"
            }
            return URLQueryItem(name: item.key, value: value)
        }
    }
}
