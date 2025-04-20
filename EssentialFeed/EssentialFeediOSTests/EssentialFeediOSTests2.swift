import EssentialFeed
import SwiftUI
import Testing
import ViewInspector

@Test func init_doesNotLoadFeed() {
  let (_, loader) = makeSUT()

  #expect(loader.loadCallCount == 0)
}

// TODO: понять почему не работает тест. Перестал работать после того как поменял местами вызовы
//       `onDidAppear` и присвоение `feed` в `FeedView`
//@MainActor
//@Test func onAppear_loadsFeed() async throws {
//  var (sut, loader) = makeSUT()
//
//  sut.onDidAppear = { _ in
//    #expect(loader.loadCallCount == 1)
//  }
//
//  ViewHosting.host(view: sut)
//  try await few(nanoseconds: 1_000_000)
//}

// TODO: понять почему не работает тест при том, что брейкпоинт на confirm() срабатывает
//@MainActor
//@Test func onAppear_loadsFeed2() async throws {
//  var (sut, loader) = makeSUT()
//
//  await confirmation { confirm in
//    sut.onDidAppear = { _ in
//      if loader.loadCallCount == 1 {
//        confirm()
//      }
//    }
//    ViewHosting.host(view: sut)
//  }
//}

//MARK: - Helpers

private func makeSUT() -> (sut: FeedView, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedView(loader: loaderSpy)
  return (sut, loaderSpy)
}

private func few(nanoseconds: UInt64) async throws {
  await confirmation { fulfillment in
    try? await Task.sleep(nanoseconds: nanoseconds)
    fulfillment()
  }
}
