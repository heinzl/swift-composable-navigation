import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test
struct ChangingTabs {
	
	// MARK: TCA
	
	enum Screen: String {
		case one
		case two
	}
	
	struct State: Equatable {
		var tabNavigation = TabNavigation<Screen>.State(
			items: [.one, .two],
			activeItem: .one
		)
	}
	
	enum Action: Equatable {
		case tabNavigation(TabNavigation<Screen>.Action)
	}
	
	struct Environment {}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		TabNavigation<Screen>.reducer()
			.pullback(
				state: \State.tabNavigation,
				action: /Action.tabNavigation,
				environment: { _ in () }
			)
	])
	
	// MARK: View creation
	
	struct TabView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				Text(viewStore.tabNavigation.activeItem.rawValue)
					.accessibilityIdentifier("tabsState")
			}
		}
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			let tabBarItem: UITabBarItem
			switch navigationItem {
			case .one:
				tabBarItem = .init(title: "one", image: nil, tag: 1)
			case .two:
				tabBarItem = .init(title: "two", image: nil, tag: 2)
			}
			let viewController = UIHostingController(rootView: TabView(store: store))
			viewController.tabBarItem = tabBarItem
			return viewController
		}
	}
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		TabNavigationViewController(
			store: store.scope(
				state: \.tabNavigation,
				action: ChangingTabs.Action.tabNavigation
			),
			viewProvider: ChangingTabs.ViewProvider(store: store)
		)
	}
}

