import Foundation

public typealias HTTPClientResponse = (HTTPURLResponse, Data)

public protocol HTTPClient {
  func get(from url: URL) throws -> HTTPClientResponse
}

