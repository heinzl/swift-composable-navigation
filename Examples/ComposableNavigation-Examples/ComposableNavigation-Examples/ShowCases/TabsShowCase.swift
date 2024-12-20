import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

/// This example showcases tab navigation with three tabs.
/// - Two counter screens and a helper screen.
/// - You can navigate to another tab.
/// - You can switch the tab order tab.
@Reducer
struct TabsShowcase {
	
	// MARK: TCA
	
	enum Screen: CaseIterable {
		case counterOne
		case counterTwo
		case helper
	}
	
	@ObservableState
	struct State: Equatable {
		var counterOne = Counter.State(id: 1, showDone: false)
		var counterTwo = Counter.State(id: 2, showDone: false)
		var helper = Helper.State()
		
		var tabNavigation = TabNavigation<Screen>.State(
			items: Screen.allCases,
			activeItem: .counterOne
		)
	}
	
	@CasePathable
	enum Action {
		case counterOne(Counter.Action)
		case counterTwo(Counter.Action)
		case helper(Helper.Action)
		
		case tabNavigation(TabNavigation<Screen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .helper(.switchTabs):
			var newOrder = state.tabNavigation.items
			newOrder.swapAt(0, newOrder.count-1)
			return .send(.tabNavigation(.setItems(newOrder)))
		case .helper(.showTab(let index)):
			return .send(.tabNavigation(.setActiveIndex(index)))
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.counterOne, action: \.counterOne) {
			Counter()
		}
		Scope(state: \.counterTwo, action: \.counterTwo) {
			Counter()
		}
		Scope(state: \.helper, action: \.helper) {
			Helper()
		}
		Scope(state: \.tabNavigation, action: \.tabNavigation) {
			TabNavigation<Screen>()
		}
		Reduce(privateReducer)
	}
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counterOne:
				let view = CounterView(
					store: store.scope(
						state: \.counterOne,
						action: \.counterOne
					)
				)
				return makeHostingView(
					view,
					with: UITabBarItem(
						title: "Counter one",
						image: UIImage(systemName: "1.circle.fill"),
						tag: 0
					)
				)
			case .counterTwo:
				let view = CounterView(
					store: store.scope(
						state: \.counterTwo,
						action: \.counterTwo
					)
				)
				return makeHostingView(
					view,
					with: UITabBarItem(
						title: "Counter two",
						image: UIImage(systemName: "2.circle.fill"),
						tag: 1
					)
				)
			case .helper:
				let view = HelperView(
					store: store.scope(
						state: \.helper,
						action: \.helper
					)
				)
				return makeHostingView(
					view,
					with: UITabBarItem(
						title: "Helper",
						image: UIImage(systemName: "mustache.fill"),
						tag: 2
					)
				)
			}
		}
		
		private func makeHostingView<T: View>(
			_ view: T,
			with tabBarItem: UITabBarItem
		) -> UIHostingController<T> {
			let viewController = UIHostingController(rootView: view)
			viewController.tabBarItem = tabBarItem
			return viewController
		}
	}
	
	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		TabNavigationViewController(
			store: store.scope(
				state: \.tabNavigation,
				action: \.tabNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}

// MARK: Helper

extension TabsShowcase {
	@Reducer
	struct Helper {
		@ObservableState
		struct State: Equatable {}
		
		@CasePathable
		enum Action {
			case switchTabs
			case showTab(Int)
		}
	}

	struct HelperView: View {
		let store: StoreOf<Helper>
		
		var body: some View {
			VStack(spacing: 20) {
				Button("Switch tabs") {
					store.send(.switchTabs)
				}
				Button("Show second tab") {
					store.send(.showTab(1))
				}
			}
		}
	}
}
