import Testing
import Foundation
import EssentialFeed

struct URLSessionHTTPClient: HTTPClient {
  let session: URLSession

  init(session: URLSession = URLSession.shared) {
    self.session = session
  }

  func get(from url: URL) async throws -> HTTPClientResponse {
    var resultResponse: HTTPURLResponse?
    var resultData: Data?
    var resultError: Error?

    do {
      let result = try await session.data(from: url)
      resultResponse = result.1 as? HTTPURLResponse
      resultData = result.0
    } catch { resultError = error }

    guard resultError == nil, let resultResponse, let resultData else {
      throw resultError ?? NSError(domain: "Network request failed without an error", code: 0)
    }

    return (resultResponse, resultData)
  }
}

@Suite(.serialized)
final class URLSessionHTTPClientTests {
  init() { URLProtocolStub.startInterceptingRequests() }
  deinit { URLProtocolStub.stopInterceptingRequests() }

  @Test func getFromURL_performsGETRequestWithAGivenURL() async throws {
    let url = URL(string: "https://some-url.ru")!
    URLProtocolStub.stub(data: nil, response: nil, error: NSError(domain: "test", code: 0))

    _ = try? await makeSUT().get(from: url)

    let (observedURL, observedMethod) = try await URLProtocolStub.observeRequest()

    #expect(observedURL == url)
    #expect(observedMethod == "GET")
  }

  @Test func getFromURL_failsOnRequestError() async {
    let url = URL(string: "https://some-url.ru")!
    let expectedError = NSError(domain: "test error", code: 0)
    URLProtocolStub.stub(data: nil, response: nil, error: expectedError)

    do {
      _ = try await makeSUT().get(from: url)
    } catch let receivedError as NSError {
      #expect(receivedError.domain == expectedError.domain)
    } catch { Issue.record("Could not cast error to NSError: \(error)") }
  }

  // MARK: - Helpers

  private func makeSUT() -> URLSessionHTTPClient {
    URLSessionHTTPClient()
  }

  private class URLProtocolStub: URLProtocol {
    private static var request: URLRequest?
    private static var stubs = [Stub]()

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }

    static func observeRequest() async throws -> (URL, String) {
      if let url = Self.request?.url, let method = Self.request?.httpMethod {
        return (url, method)
      } else {
        throw NSError(domain: "No request", code: 0)
      }
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
      stubs.append(Stub(data: data, response: response, error: error))
    }

    static func startInterceptingRequests() {
      URLProtocol.registerClass(Self.self)
    }

    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(Self.self)
      stubs = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
      Self.request = request
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      guard let stub = Self.stubs.first else { return }

      if let data = stub.data {
        client?.urlProtocol(self, didLoad: data)
      }
      if let response = stub.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      if let error = stub.error {
        client?.urlProtocol(self, didFailWithError: error)
      }

      client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
  }
}
