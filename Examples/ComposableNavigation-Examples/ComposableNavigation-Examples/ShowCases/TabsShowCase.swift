import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

struct TabsShowcase {
	
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
	
	struct Environment {}
	
	private static let privateRducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .helper(.switchTabs):
			var newOrder = state.tabNavigation.items
			newOrder.swapAt(0, newOrder.count-1)
			return Effect(value: .tabNavigation(.setItems(newOrder)))
		case .helper(.showTab(let index)):
			return Effect(value: .tabNavigation(.setActiveIndex(index)))
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		Counter.reducer
			.pullback(
				state: \State.counterOne,
				action: /Action.counterOne,
				environment: { _ in .init() }
			),
		Counter.reducer
			.pullback(
				state: \State.counterTwo,
				action: /Action.counterTwo,
				environment: { _ in .init() }
			),
		Helper.reducer
			.pullback(
				state: \State.helper,
				action: /Action.helper,
				environment: { _ in .init() }
			),
		TabNavigation<Screen>.reducer()
			.pullback(
				state: \State.tabNavigation,
				action: /Action.tabNavigation,
				environment: { _ in () }
			),
		privateRducer
	])
	
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
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController{
		TabNavigationController(
			store: store.scope(
				state: \.tabNavigation,
				action: TabsShowcase.Action.tabNavigation
			),
			viewProvider: TabsShowcase.ViewProvider(store: store)
		)
	}
}

// MARK: Helper

extension TabsShowcase {
	struct Helper {
		struct State: Equatable {}
		
		enum Action: Equatable {
			case switchTabs
			case showTab(Int)
		}
		
		struct Environment {}
		
		static let reducer: Reducer<State, Action, Environment> = .empty
	}

	struct HelperView: View {
		let store: Store<Helper.State, Helper.Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				VStack(spacing: 20) {
					Button("Switch tabs") {
						viewStore.send(.switchTabs)
					}
					Button("Show second tab") {
						viewStore.send(.showTab(1))
					}
				}
			}
		}
	}
}
