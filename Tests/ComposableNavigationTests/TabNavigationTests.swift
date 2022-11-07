import Foundation
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

@MainActor
class TabNavigationTests: XCTestCase {
	func testSetActiveItem() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveItem(2)) {
			$0.activeItem = 2
		}
	}
	
	func testSetActiveItemOutOfBounds() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveItem(99))
	}
	
	func testSetActiveIndex() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveIndex(2)) {
			$0.activeItem = 3
		}
	}
	
	func testSetActiveIndexOutOfBounds() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveIndex(99))
	}
	
	func testSetItems() async {
		let store = makeStore(.init(items: [1, 2], activeItem: 1))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	func testSetItemsFromEmpty() async {
		let store = makeStore(.init(items: [], activeItem: 1))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	func testSetSameItemsDifferentOrder() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setItems([3, 2, 1])) {
			$0.items = [3, 2, 1]
		}
	}
	
	func testDisablingAnimation() async {
		let store = makeStore(.init(items: [1, 2], activeItem: 1))
		
		await store.send(.setItems([1, 2], animated: false)) {
			$0.areAnimationsEnabled = false
		}
	}
	
	func testDisablingAnimationAndSettingsItems() async {
		let store = makeStore(.init(items: [1, 2], activeItem: 1))
		
		await store.send(.setItems([3, 4], animated: false)) {
			$0.items = [3, 4]
			$0.activeItem = 3
			$0.areAnimationsEnabled = false
		}
	}
	
	// MARK: Helper
	
	private typealias TestFeature = TabNavigation<Int>
	
	private func makeStore(
		_ state: TestFeature.State
	) -> TestStore<
		TestFeature.State,
		TestFeature.Action,
		TestFeature.State,
		TestFeature.Action,
		()
	> {
		TestStore(initialState: state, reducer: TestFeature())
	}
}

