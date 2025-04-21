import EssentialFeed
import SwiftUI
import ViewInspector
import XCTest

struct FeedView: View {
  @State public var loader: FeedLoader
  @State public var feed: [FeedItem]?
  @State private var loadingIndicatorOpacity: CGFloat = 1
  var onDidAppear: ((Self) -> Void)?
  var onFeedChange: ((Self) -> Void)?
  var onFinishRefreshing: ((Self) -> Void)?

  init(loader: FeedLoader) {
    self.loader = loader
  }

  var body: some View {
    NavigationView {
      List {}
        .refreshable(action: refresh)
        .overlay {
          ProgressView()
            .id("loading indicator")
            .opacity(loadingIndicatorOpacity)
        }
    }
    .onAppear {
      Task {
        self.onDidAppear?(self)
        await refresh()
      }
    }
  }

  @Sendable
  func refresh() async {
    do {
      feed = try await loader.load()
      withAnimation { loadingIndicatorOpacity = 0 }
      self.onFinishRefreshing?(self)
    } catch {}
  }
}

@MainActor
class EssentialFeediOSXCTests: XCTestCase {
  func test_init_doesNotLoadFeed() {
    let (_, loader) = makeSUT()
    XCTAssertEqual(loader.loadCallCount, 0)
  }

  func test_loadFeedActions_requestFeedFromLoader() async {
    var (sut, loader) = makeSUT()

    let viewAppears = sut.on(\.onFinishRefreshing)
    { _ in XCTAssertEqual(loader.loadCallCount, 1) }
    ViewHosting.host(view: sut)
    await fulfillment(of: [viewAppears], timeout: 0.1)

    let firstUserInitiatedReload = sut.on(\.onFinishRefreshing)
    { _ in XCTAssertEqual(loader.loadCallCount, 2) }
    await sut.refresh()
    await fulfillment(of: [firstUserInitiatedReload], timeout: 0.1)

    let secondUserInitiatedReload = sut.on(\.onFinishRefreshing)
    { _ in XCTAssertEqual(loader.loadCallCount, 3) }
    await sut.refresh()
    await fulfillment(of: [secondUserInitiatedReload], timeout: 0.1)
  }

  func test_loadingFeedIndicator_isVisibleOnlyWhileLoadingFeed() async throws {
    var (sut, _) = makeSUT()

    let viewAppears = sut.on(\.onDidAppear) { view in
      XCTAssertTrue(try isShowingLoadingIndicator(for: view))
    }
    let feedLoadingCompletes = sut.on(\.onFinishRefreshing) { view in
      XCTAssertFalse(try isShowingLoadingIndicator(for: view))
    }

    ViewHosting.host(view: sut)
    await fulfillment(of: [viewAppears, feedLoadingCompletes])
  }
}

//MARK: - Helpers

private func makeSUT() -> (sut: FeedView, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedView(loader: loaderSpy)
  return (sut, loaderSpy)
}

private func isShowingLoadingIndicator(
  for view: InspectableView<ViewType.View<FeedView>>
) throws -> Bool {
  let indicator = try view.find(viewWithId: "loading indicator")
  return try indicator.opacity() != 0
}

final class LoaderSpy: FeedLoader, @unchecked Sendable {
  private(set) var loadCallCount = 0

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    return [FeedItem(id: UUID(), imageURL: URL(string: "http://some-url.ru")!)]
  }
}
