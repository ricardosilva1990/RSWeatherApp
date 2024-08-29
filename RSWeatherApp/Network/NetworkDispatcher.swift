import Combine
import Foundation

struct NetworkDispatcher {
    let urlSession: URLSession
    let decoder: JSONDecoder

    init(urlSession: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.urlSession = urlSession
        self.decoder = decoder
    }

    /// Dispatches an URLRequest and returns a publisher
    /// - Parameter request: URLRequest
    /// - Returns: A publisher with the provided decoded data or an error
    func dispatch<ReturnType: Codable>(_ request: URLRequest) -> AnyPublisher<ReturnType, NetworkRequestError> {
        self.urlSession
            .dataTaskPublisher(for: request)
            // Map on Request response
            .tryMap { data, response in
                // If the response is invalid, throw an error
                if let response = response as? HTTPURLResponse,
                   !(200...299).contains(response.statusCode) {
                    throw self.httpError(response.statusCode)
                }
                // Return Response data
                return data
            }
            // Decode data using our ReturnType
            .decode(type: ReturnType.self, decoder: self.decoder)
            // Handle any decoding errors
            .mapError { self.handleError($0) }
            // And finally, expose our publisher
            .eraseToAnyPublisher()
    }
}

private extension NetworkDispatcher {
    /// Parses a HTTP StatusCode and returns a proper error
    /// - Parameter statusCode: HTTP status code
    /// - Returns: Mapped Error
    func httpError(_ statusCode: Int) -> NetworkRequestError {
        switch statusCode {
        case 400: .badRequest
        case 401: .unauthorized
        case 403: .forbidden
        case 404: .notFound
        case 402, 405...499: .error4xx(statusCode)
        case 500: .serverError
        case 501...599: .error5xx(statusCode)
        default: .unknownError
        }
    }

    /// Parses URLSession Publisher errors and return proper ones
    /// - Parameter error: URLSession publisher error
    /// - Returns: Readable NetworkRequestError
    func handleError(_ error: Error) -> NetworkRequestError {
        switch error {
        case is Swift.DecodingError: .decodingError
        case let urlError as URLError: .urlSessionFailed(urlError)
        case let error as NetworkRequestError: error
        default:  .unknownError
        }
    }
}
