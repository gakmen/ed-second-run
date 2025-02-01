import Foundation

public struct URLSessionHTTPClient: HTTPClient {
  public init() {}

  public func get(from url: URL) async throws -> HTTPClientResponse {
    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      if let httpResponse = response as? HTTPURLResponse {
        return (httpResponse, data)
      } else {
        throw UnexpectedResponse()
      }
    } catch {
      throw error
    }
  }

  public struct UnexpectedResponse: Error {}
}
