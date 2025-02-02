import Testing
import Foundation
import EssentialFeed

@Test(arguments: (0...7))
func testServerGETFeedResult_matchesFixedTestAcoountData(i: Int) async throws {
  let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
  let client = URLSessionHTTPClient()
  let loader = RemoteFeedLoader(url: testServerURL, client: client)

  let result = try await loader.load()

  #expect(result[i].id == UUID(uuidString: uuids[i]))
  #expect(result[i].description == descriptions[i])
  #expect(result[i].location == locations[i])
  #expect(result[i].imageURL == imageURLs()[i])
}

// MARK: - Helpers

private let uuids: [String] = [
  "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
  "BA298A85-6275-48D3-8315-9C8F7C1CD109",
  "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
  "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
  "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
  "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
  "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
  "F79BD7F8-063F-46E2-8147-A67635C3BB01"
]

private let descriptions: [String?] = [
  "Description 1",
  nil,
  "Description 3",
  nil,
  "Description 5",
  "Description 6",
  "Description 7",
  "Description 8"
]

private let locations: [String?] = [
  "Location 1",
  "Location 2",
  nil,
  nil,
  "Location 5",
  "Location 6",
  "Location 7",
  "Location 8"
]

private func imageURLs() -> [URL] {
  var result = [URL]()
  (1...8).forEach { result.append(URL(string: "https://url-\($0).com")!) }
  return result
}

private func expectedFeedItem(at index: Int) -> FeedItem {
  FeedItem(
    id: UUID(uuidString: uuids[index])!,
    description: descriptions[index],
    location: locations[index],
    imageURL: imageURLs()[index]
  )
}
