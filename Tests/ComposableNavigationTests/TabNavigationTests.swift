import Foundation
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

class TabNavigationTests: XCTestCase {
	@MainActor
	func testSetActiveItem() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveItem(2)) {
			$0.activeItem = 2
		}
	}
	
	@MainActor
	func testSetActiveItemOutOfBounds() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveItem(99))
	}
	
	@MainActor
	func testSetActiveIndex() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveIndex(2)) {
			$0.activeItem = 3
		}
	}
	
	@MainActor
	func testSetActiveIndexOutOfBounds() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setActiveIndex(99))
	}
	
	@MainActor
	func testSetItems() async {
		let store = makeStore(.init(items: [1, 2], activeItem: 1))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	@MainActor
	func testSetItemsFromEmpty() async {
		let store = makeStore(.init(items: [], activeItem: 1))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	@MainActor
	func testSetSameItemsDifferentOrder() async {
		let store = makeStore(.init(items: [1, 2, 3], activeItem: 1))
		
		await store.send(.setItems([3, 2, 1])) {
			$0.items = [3, 2, 1]
		}
	}
	
	@MainActor
	func testDisablingAnimation() async {
		let store = makeStore(.init(items: [1, 2], activeItem: 1))
		
		await store.send(.setItems([1, 2], animated: false)) {
			$0.areAnimationsEnabled = false
		}
	}
	
	@MainActor
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
	
	@MainActor
	private func makeStore(
		_ state: TestFeature.State
	) -> TestStoreOf<TestFeature> {
		TestStore(initialState: state, reducer: { TestFeature() })
	}
}

