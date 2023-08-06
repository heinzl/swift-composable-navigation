#if canImport(ComposableArchitecture)
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

class StoreCompactMapTest: XCTestCase {
	func testCompactMapNonOptional() throws {
		let store = Store<Int?, Void>(initialState: 12, reducer: EmptyReducer())
		let compactMappedStore = try XCTUnwrap(
			store.compactMap({ $0.scope(state: { $0 * 2 }) }),
			"Store should not be nil after compactMap"
		)
		XCTAssertEqual(ViewStore(compactMappedStore).state, 24)
	}
	
	func testCompactMapOptional() throws {
		let store = Store<Int?, Void>(initialState: nil, reducer: EmptyReducer())
		let compactMappedStore = store.compactMap({ $0.scope(state: { $0 * 2 }) })
		XCTAssertNil(compactMappedStore)
	}
}
#endif
