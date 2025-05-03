import EssentialFeed
import EssentialFeediOS
import SwiftUI
import ViewInspector
import XCTest

@MainActor
class EssentialFeediOSXCTests: XCTestCase {
  func test_init_doesNotLoadFeed() {
    let (_, loader) = makeSUTOfModel()
    XCTAssertEqual(loader.loadCallCount, 0)
  }

  func test_loadFeedActions_requestFeedFromLoader() async throws {
    let (sut, loader) = makeSUTOfModel()

    try await sut.refresh()
    XCTAssertEqual(loader.loadCallCount, 1)

    try await sut.refresh()
    XCTAssertEqual(loader.loadCallCount, 2)

    try await sut.refresh()
    XCTAssertEqual(loader.loadCallCount, 3)
  }

  func test_loadingFeedIndicator_isInvisibleOnRefreshCompletion() async throws {
    let (sut, _) = makeSUTOfModel()

    XCTAssertTrue(sut.showLoadingIndicator)
    try await sut.refresh()
    XCTAssertFalse(sut.showLoadingIndicator)
  }

  func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() async throws {
    var (sut, loader) = makeSUT()
    let expectedItem0 = makeItem(description: "a description", location: "a location")
    let expectedItem1 = makeItem(description: nil, location: "another location")
    let expectedItem2 = makeItem(description: "another description", location: nil)
    let expectedItem3 = makeItem(description: nil, location: nil)

    // First load
    loader.feedStub = [expectedItem0]
    let feedLoadingCompletes = sut.on(\.onFinishRefreshing) { view in
      assertThat(view, isRendering: [expectedItem0])
    }
    ViewHosting.host(view: sut)
    await fulfillment(of: [feedLoadingCompletes])

    // Second load
    let expectedItems = [expectedItem0, expectedItem1, expectedItem2, expectedItem3]
    loader.feedStub = expectedItems
    let userInitiatedReloadCompletes = sut.on(\.onFinishRefreshing) { view in
      assertThat(view, isRendering: expectedItems)
    }
    ViewHosting.host(view: sut)
    await fulfillment(of: [userInitiatedReloadCompletes])
  }
}

//MARK: - Helpers

private func makeSUT() -> (sut: FeedView, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedView(loader: loaderSpy)
  return (sut, loaderSpy)
}

private func makeSUTOfModel() -> (sut: FeedViewModel, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedViewModel(loader: loaderSpy)
  return (sut, loaderSpy)
}

private func isShowingLoadingIndicator(
  for view: InspectableView<ViewType.View<FeedView>>
) throws -> Bool {
  let indicator = try view.find(viewWithId: "loading indicator")
  return try indicator.opacity() != 0
}

private func makeItem(
  description: String? = nil,
  location: String? = nil,
  url: URL = URL(string: "http://some-url.ru")!
) -> FeedItem {
  .init(id: UUID(), description: description, location: location, imageURL: url)
}

private func assertThat(
  _ view: InspectableView<ViewType.View<FeedView>>,
  isRendering expectedItems: [FeedItem],
  file: StaticString = #file,
  line: UInt = #line
) {
  let itemViews = view.findAll(ViewType.VStack.self)
  XCTAssertEqual(itemViews.count, expectedItems.count, file: file, line: line)
  expectedItems.indices.forEach { index in
    assertThat(itemViews, contain: expectedItems, at: index)
  }
}

private func assertThat(
  _ itemViews: [InspectableView<ViewType.VStack>],
  contain expectedItems: [FeedItem],
  at index: Int,
  file: StaticString = #file,
  line: UInt = #line
) {
  assertProperty(
    in: itemViews,
    expectedItems: expectedItems,
    at: index,
    viewId: "location",
    expected: expectedItems[index].location,
    propertyName: "location",
    file: file,
    line: line
  )

  assertProperty(
    in: itemViews,
    expectedItems: expectedItems,
    at: index,
    viewId: "description",
    expected: expectedItems[index].description,
    propertyName: "description",
    file: file,
    line: line
  )
}

private func assertProperty(
  in itemViews: [InspectableView<ViewType.VStack>],
  expectedItems: [FeedItem],
  at index: Int,
  viewId: String,
  expected: String?,
  propertyName: String,
  file: StaticString = #file,
  line: UInt = #line
) {
  if let receivedValue = try? itemViews[index].find(viewWithId: viewId).text().string() {
    XCTAssertEqual(
      receivedValue, expected,
            """
            Expected \(propertyName) text at index: \(index) to be: \(receivedValue), 
            got \(String(describing: expected)) instead
            """,
      file: file,
      line: line
    )
  } else {
    XCTAssertNil(
      expected,
            """
            Expected NO \(propertyName) text at index: \(index),
            got \(String(describing: expected)) instead
            """,
      file: file,
      line: line
    )
  }
}

final class LoaderSpy: FeedLoader, @unchecked Sendable {
  private(set) var loadCallCount = 0
  var feedStub = [FeedItem]()

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    return feedStub
  }
}
