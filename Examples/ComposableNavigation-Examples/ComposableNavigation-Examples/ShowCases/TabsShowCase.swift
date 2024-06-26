import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

/// This example showcases tab navigation with three tabs.
/// - Two counter screens and a helper screen.
/// - You can navigate to another tab.
/// - You can switch the tab order tab.
struct TabsShowcase: Reducer {
	
	// MARK: TCA
	
	enum Screen: CaseIterable {
		case counterOne
		case counterTwo
		case helper
	}
	
	struct State: Equatable {
		var counterOne = Counter.State(id: 1, showDone: false)
		var counterTwo = Counter.State(id: 2, showDone: false)
		var helper = Helper.State()
		
		var tabNavigation = TabNavigation<Screen>.State(
			items: Screen.allCases,
			activeItem: .counterOne
		)
	}
	
	enum Action: Equatable {
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
	
	var body: some Reducer<State, Action> {
		Scope(state: \.counterOne, action: /Action.counterOne) {
			Counter()
		}
		Scope(state: \.counterTwo, action: /Action.counterTwo) {
			Counter()
		}
		Scope(state: \.helper, action: /Action.helper) {
			Helper()
		}
		Scope(state: \.tabNavigation, action: /Action.tabNavigation) {
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
						action: Action.counterOne
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
						action: Action.counterTwo
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
						action: Action.helper
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
				action: Action.tabNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}

// MARK: Helper

extension TabsShowcase {
	struct Helper: Reducer {
		struct State: Equatable {}
		
		enum Action: Equatable {
			case switchTabs
			case showTab(Int)
		}
		
		func reduce(into state: inout State, action: Action) -> Effect<Action> {
			.none
		}
	}

	struct HelperView: View {
		let store: Store<Helper.State, Helper.Action>
		
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
