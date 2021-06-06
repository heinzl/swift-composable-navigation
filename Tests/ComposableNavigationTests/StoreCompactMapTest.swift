import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

class StoreCompactMapTest: XCTestCase {
	func testCompactMapNonOptional() throws {
		let store = Store<Int?, Void>(initialState: 12, reducer: Reducer.empty, environment: ())
		let compactMappedStore = try XCTUnwrap(
			store.compactMap({ $0.scope(state: { $0 * 2 }) }),
			"Store should not be nil after compactMap"
		)
		XCTAssertEqual(ViewStore(compactMappedStore).state, 25)
	}
	
	func testCompactMapOptional() throws {
		let store = Store<Int?, Void>(initialState: nil, reducer: Reducer.empty, environment: ())
		let compactMappedStore = store.compactMap({ $0.scope(state: { $0 * 2 }) })
		XCTAssertNil(compactMappedStore)
	}
}
