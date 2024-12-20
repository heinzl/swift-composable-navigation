import Foundation
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

class StackNavigationTests: XCTestCase {
	@MainActor
	func testPushItem() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.pushItem(1)) {
			$0.items = [1]
		}
	}
	
	@MainActor
	func testPushItemOnExistingStack() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.pushItem(3)) {
			$0.items = [1, 2, 3]
		}
	}
	
	@MainActor
	func testPushItems() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.pushItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	@MainActor
	func testPushItemsOnExistingStack() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.pushItems([3, 4])) {
			$0.items = [1, 2, 3, 4]
		}
	}
	
	@MainActor
	func testPopItem() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.popItem()) {
			$0.items = [1]
		}
	}
	
	@MainActor
	func testPopItemsCount() async {
		let store = makeStore(.init(items: [1, 2, 3]))
		
		await store.send(.popItems(count: 2)) {
			$0.items = [1]
		}
	}
	
	@MainActor
	func testPopItemFromEmptyStack() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.popItem())
	}
	
	@MainActor
	func testPopTooManyItems() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.popItems(count: 5))
	}
	
	@MainActor
	func testPopToRoot() async {
		let store = makeStore(.init(items: [1, 2, 3]))
		
		await store.send(.popToRoot()) {
			$0.items = [1]
		}
	}
	
	@MainActor
	func testPopToRootOnEmptyStack() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.popToRoot())
	}
	
	@MainActor
	func testPopToRootWithOnlyRoot() async {
		let store = makeStore(.init(items: [1]))
		
		await store.send(.popToRoot())
	}
	
	@MainActor
	func testSetItems() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	@MainActor
	func testSetItemsFromEmpty() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	@MainActor
	func testSetSameItemsDifferentOrder() async {
		let store = makeStore(.init(items: [1, 2, 3]))
		
		await store.send(.setItems([3, 2, 1])) {
			$0.items = [3, 2, 1]
		}
	}
	
	@MainActor
	func testDisablingAnimation() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.setItems([1, 2], animated: false)) {
			$0.areAnimationsEnabled = false
		}
	}
	
	@MainActor
	func testDisablingAnimationAndSettingsItems() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.setItems([3, 4], animated: false)) {
			$0.items = [3, 4]
			$0.areAnimationsEnabled = false
		}
	}
	
	// MARK: Helper
	
	private typealias TestFeature = StackNavigation<Int>
	
	@MainActor
	private func makeStore(
		_ state: TestFeature.State
	) -> TestStoreOf<TestFeature> {
		TestStore(initialState: state, reducer: { TestFeature() })
	}
}
