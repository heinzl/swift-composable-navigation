import Foundation
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

class ModalNavigationTests: XCTestCase {
	@MainActor
	func testPresentingFullScreenItem() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.presentFullScreen(1)) {
			$0.styledItem = .init(item: 1, style: .fullScreen)
		}
	}
	
	@MainActor
	func testPresentingSheetItem() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.presentSheet(1)) {
			$0.styledItem = .init(item: 1, style: .pageSheet)
		}
	}
	
	@MainActor
	func testSettingModalItem() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.set(.init(item: 1, style: .currentContext))) {
			$0.styledItem = .init(item: 1, style: .currentContext)
		}
	}
	
	@MainActor
	func testDismissingItem() async {
		let store = makeStore(.init(styledItem: .init(item: 1, style: .pageSheet)))
		
		await store.send(.dismiss()) {
			$0.styledItem = nil
		}
	}
	
	@MainActor
	func testDismissingWithoutItem() async {
		let store = makeStore(.init(styledItem: nil))
		store.exhaustivity = .off
		
		await store.send(.dismiss()) {
			$0.styledItem = nil
		}
	}
	
	@MainActor
	func testChangingStyle() async {
		let store = makeStore(.init(styledItem: .init(item: 1, style: .pageSheet)))
		
		await store.send(.set(.init(item: 1, style: .overFullScreen))) {
			$0.styledItem = .init(item: 1, style: .overFullScreen)
		}
	}
	
	@MainActor
	func testChangingItem() async {
		let store = makeStore(.init(styledItem: .init(item: 1, style: .pageSheet)))
		
		await store.send(.set(.init(item: 2, style: .pageSheet))) {
			$0.styledItem = .init(item: 2, style: .pageSheet)
		}
	}
	
	@MainActor
	func testDisablingAnimation() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.set(.init(item: 1, style: .pageSheet), animated: false)) {
			$0.styledItem = .init(item: 1, style: .pageSheet)
			$0.areAnimationsEnabled = false
		}
	}
	
	// MARK: Helper
	
	private typealias TestFeature = ModalNavigation<Int>
	
	private func makeStore(
		_ state: TestFeature.State
	) -> TestStoreOf<TestFeature> {
		TestStore(initialState: state, reducer: { TestFeature() })
	}
}
