import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

class StoreCompactMapTest: XCTestCase {
	@MainActor
	func testCompactMapNonOptional() throws {
		let store = Store<Int?, Void>(initialState: 12, reducer: { EmptyReducer() })
		let compactMappedStore = try XCTUnwrap(
			store.compactMap({ $0.scope(state: { $0 * 2 }, action: { $0 }) }),
			"Store should not be nil after compactMap"
		)
		XCTAssertEqual(compactMappedStore.withState { $0 }, 24)
	}
	
	@MainActor
	func testCompactMapOptional() throws {
		let store = Store<Int?, Void>(initialState: nil, reducer: { EmptyReducer() })
		let compactMappedStore = store.compactMap({ $0.scope(state: { $0 * 2 }, action: { $0 }) })
		XCTAssertNil(compactMappedStore)
	}
}
