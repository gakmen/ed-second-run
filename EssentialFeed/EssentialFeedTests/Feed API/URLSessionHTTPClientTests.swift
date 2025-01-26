import Testing
import Foundation
import EssentialFeed

struct URLSessionHTTPClient: HTTPClient {
  func get(from url: URL) throws -> HTTPClientResponse {
    var resultResponse: HTTPURLResponse?
    var resultData: Data?
    var resultError: Error?

    let semaphore = DispatchSemaphore(value: 0)
    Task {
      defer { semaphore.signal() }
      do {
        let result = try await URLSession.shared.data(from: url)
        resultResponse = result.1 as? HTTPURLResponse
        resultData = result.0
      } catch { resultError = error }
    }
    semaphore.wait()

    guard resultError == nil, let resultResponse, let resultData else {
      throw resultError ?? NSError(domain: "Network request failed without an error", code: 0)
    }

    return (resultResponse, resultData)
  }
}

final class URLSessionHTTPClientTests {
  init() { URLProtocolStub.startInterceptingRequests() }
  deinit { URLProtocolStub.stopInterceptingRequests() }

  @Test func getFromURL_failsOnRequestError() {
    let sut = URLSessionHTTPClient()
    let url = URL(string: "https://some-url.ru")!
    let expectedError = NSError(domain: "test error", code: 0)
    URLProtocolStub.stub(data: nil, response: nil, error: expectedError)

    do {
      _ = try sut.get(from: url)
    } catch let receivedError as NSError {
      #expect(receivedError.domain == expectedError.domain)
    } catch { Issue.record("Could not cast error to NSError: \(error)") }
  }

  // MARK: - Helpers

  private class URLProtocolStub: URLProtocol {
    private static var stubs = [Stub]()

    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
      stubs.append(Stub(data: data, response: response, error: error))
    }

    static func startInterceptingRequests() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stubs = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      guard let stub = URLProtocolStub.stubs.first else { return }

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
