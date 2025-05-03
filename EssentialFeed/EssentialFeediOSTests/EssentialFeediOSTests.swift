import EssentialFeed
import EssentialFeediOS
import SwiftUI
import ViewInspector
import XCTest

@MainActor
class EssentialFeediOSXCTests: XCTestCase {
  func test_init_doesNotLoadFeed() {
    let (_, loader) = makeSUT()
    XCTAssertEqual(loader.loadCallCount, 0)
  }

  func test_loadFeedActions_requestFeedFromLoader() async {
    let (sut, loader) = makeSUT()

    await sut.refresh()
    XCTAssertEqual(loader.loadCallCount, 1)

    await sut.refresh()
    XCTAssertEqual(loader.loadCallCount, 2)

    await sut.refresh()
    XCTAssertEqual(loader.loadCallCount, 3)
  }

  func test_loadingFeedIndicator_isInvisibleOnRefreshCompletion() async {
    let (sut, _) = makeSUT()

    XCTAssertTrue(sut.showLoadingIndicator)
    await sut.refresh()
    XCTAssertFalse(sut.showLoadingIndicator)
  }

  func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() async {
    let (sut, loader) = makeSUT()
    let expectedItem0 = makeItem(description: "a description", location: "a location")
    let expectedItem1 = makeItem(description: nil, location: "another location")
    let expectedItem2 = makeItem(description: "another description", location: nil)
    let expectedItem3 = makeItem(description: nil, location: nil)

    let expectedFeed = [FeedItem]()
    loader.feedStub = expectedFeed
    let receivedFeed = sut.feed
    assertThat(receivedFeed, isEqualTo: expectedFeed)

    let expectedFeedOnFirstLoad = [expectedItem0]
    loader.feedStub = expectedFeedOnFirstLoad
    await sut.refresh()
    let receivedFeedOnFirstLoad = sut.feed
    assertThat(receivedFeedOnFirstLoad, isEqualTo: expectedFeedOnFirstLoad)

    let expectedFeedOnSecondLoad = [expectedItem0, expectedItem1, expectedItem2, expectedItem3]
    loader.feedStub = expectedFeedOnSecondLoad
    await sut.refresh()
    let receivedFeedOnSecondLoad = sut.feed
    assertThat(receivedFeedOnSecondLoad, isEqualTo: expectedFeedOnSecondLoad)
  }

  func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() async {
    let (sut, loader) = makeSUT()
    let expectedItems = [makeItem()]

    loader.feedStub = expectedItems
    await sut.refresh()
    assertThat(sut.feed, isEqualTo: expectedItems)

    loader.errorStub = NSError(domain: "an error", code: 0)
    await sut.refresh()
    assertThat(sut.feed, isEqualTo: expectedItems)
  }
}

//MARK: - Helpers

private func makeSUT() -> (sut: FeedViewModel, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedViewModel(loader: loaderSpy)
  return (sut, loaderSpy)
}

private func makeItem(
  description: String? = nil,
  location: String? = nil,
  url: URL = URL(string: "http://some-url.ru")!
) -> FeedItem {
  .init(id: UUID(), description: description, location: location, imageURL: url)
}

private func assertThat(
  _ receivedFeed: [FeedItem],
  isEqualTo expectedFeed: [FeedItem],
  file: StaticString = #file,
  line: UInt = #line
) {
  XCTAssertEqual(
    receivedFeed.count,
    expectedFeed.count,
    "Expected to receive \(expectedFeed.count) items, got \(receivedFeed.count) instead.",
    file: file,
    line: line
  )
  receivedFeed.enumerated().forEach { index, receivedItem in
    XCTAssertEqual(receivedItem.id, expectedFeed[index].id, file: file, line: line)
    XCTAssertEqual(receivedItem.description, expectedFeed[index].description, file: file, line: line)
    XCTAssertEqual(receivedItem.location, expectedFeed[index].location, file: file, line: line)
    XCTAssertEqual(receivedFeed[index].imageURL, expectedFeed[index].imageURL, file: file, line: line)
  }
}

final class LoaderSpy: FeedLoader, @unchecked Sendable {
  private(set) var loadCallCount = 0
  var feedStub = [FeedItem]()
  var errorStub: Error?

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    if let errorStub {
      throw errorStub
    } else {
      return feedStub
    }
  }
}
