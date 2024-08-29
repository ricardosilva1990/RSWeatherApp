import Combine
import Foundation

struct APIClient {
    private let baseURLText: String
    private let networkDispatch: NetworkDispatcher

    init(baseURLText: String, networkDispatch: NetworkDispatcher = NetworkDispatcher()) {
        self.baseURLText = baseURLText
        self.networkDispatch = networkDispatch
    }

    /// Dispatches a Request
    func dispatch<Request: NetworkRequest>(
        _ request: Request
    ) -> AnyPublisher<Request.ReturnType, NetworkRequestError> {
        // TODO: Understand if we should still use `NetworkRequestError` or is `Error` enough.
        guard let urlRequest = request.toURLRequest(self.baseURLText) else {
            return Fail(
                outputType: Request.ReturnType.self, failure: NetworkRequestError.badRequest
            ).eraseToAnyPublisher()
        }
        let result: AnyPublisher<Request.ReturnType, NetworkRequestError> = self.networkDispatch.dispatch(urlRequest)
        return result.eraseToAnyPublisher()
    }
}
