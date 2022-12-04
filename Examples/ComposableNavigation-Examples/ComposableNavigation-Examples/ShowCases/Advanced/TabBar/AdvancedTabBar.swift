import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct AdvancedTabBar: ReducerProtocol {
	
	// MARK: TCA
	
	enum Screen: CaseIterable, Codable {
		case deepLink
		case listAndDetail
		case alertPlayground
		case nestedNavigation
	}
	
	struct State: Equatable, Codable {
		var deepLink = CountryDeepLink.State()
		var listAndDetail = CountryListAndDetail.State()
		var alertPlayground = AlertPlayground.State()
		var nestedNavigation = NestedStack.State(modalLevel: 1)
		
		var tabNavigation = TabNavigation<Screen>.State(
			items: Screen.allCases,
			activeItem: .deepLink
		)
	}
	
	enum Action: Equatable, Codable {
		case deepLink(CountryDeepLink.Action)
		case listAndDetail(CountryListAndDetail.Action)
		case alertPlayground(AlertPlayground.Action)
		case tabNavigation(TabNavigation<Screen>.Action)
		case nestedNavigation(NestedStack.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .deepLink(.showSorting):
			// Using actions to setup navigation
			return .run { send in
				await send(.tabNavigation(.setActiveItem(.listAndDetail)))
				await send(.listAndDetail(.stackNavigation(.setItems([.list]))))
				await send(.listAndDetail(.modalNavigation(.set(.init(item: .sort, style: .pageSheet)))))
			}
		case .deepLink(.showSortingReset):
			// Using state directly to setup navigation
			state.tabNavigation.activeItem = .listAndDetail
			state.listAndDetail.stackNavigation.items = [.list]
			state.listAndDetail.modalNavigation.styledItem = .init(item: .sort, style: .pageSheet)
			state.listAndDetail.countrySort.alertNavigation.styledItem = .init(item: .resetAlert, style: .fullScreen)
			return .none
		case .deepLink(.showCountry(let countryId)):
			return .run { send in
				await send(.tabNavigation(.setActiveItem(.listAndDetail)))
				await send(.listAndDetail(.stackNavigation(.setItems([.list, .detail(id: countryId)]))))
			}
		case .deepLink(.showAlertOptions):
			return .run { send in
				await send(.tabNavigation(.setActiveItem(.alertPlayground)))
				await send(.alertPlayground(.alertNavigation(.set(.init(item: .actionSheet, style: .fullScreen)))))
			}
		case .deepLink(.showNestedNavigation):
			state.tabNavigation.activeItem = .nestedNavigation
			state.nestedNavigation = .example
			return .none
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerProtocol<State, Action> {
		Scope(state: \.deepLink, action: /Action.deepLink) {
			CountryDeepLink()
		}
		Scope(state: \.listAndDetail, action: /Action.listAndDetail) {
			CountryListAndDetail()
		}
		Scope(state: \.alertPlayground, action: /Action.alertPlayground) {
			AlertPlayground()
		}
		Scope(state: \.nestedNavigation, action: /Action.nestedNavigation) {
			NestedStack()
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
			case .deepLink:
				let viewController = CountryDeepLink.makeView(
					store: store.scope(
						state: \.deepLink,
						action: Action.deepLink
					)
				)
				viewController.tabBarItem = UITabBarItem(
					title: "Deep link",
					image: UIImage(systemName: "link"),
					tag: 0
				)
				return viewController

			case .listAndDetail:
				let listAndDetailStore = store.scope(
					state: \.listAndDetail,
					action: Action.listAndDetail
				)
				ViewStore(listAndDetailStore).send(.loadCountries)
				let viewController = CountryListAndDetail.makeView(store: listAndDetailStore)
				viewController.tabBarItem = UITabBarItem(
					title: "List",
					image: UIImage(systemName: "list.dash"),
					tag: 1
				)
				return viewController
				
			case .alertPlayground:
				let viewController = AlertPlayground.makeView(
					store: store.scope(
						state: \.alertPlayground,
						action: Action.alertPlayground
					)
				)
				viewController.tabBarItem = UITabBarItem(
					title: "Alerts",
					image: UIImage(systemName: "exclamationmark.bubble"),
					tag: 2
				)
				return viewController
			case .nestedNavigation:
				let viewController = NestedStack.makeView(
					store: store.scope(
						state: \.nestedNavigation,
						action: Action.nestedNavigation
					)
				)
				viewController.tabBarItem = UITabBarItem(
					title: "Nested",
					image: UIImage(systemName: "square.3.layers.3d.down.left"),
					tag: 3
				)
				return viewController
			}
		}
	}
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		return TabNavigationViewController(
			store: store.scope(
				state: \.tabNavigation,
				action: Action.tabNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}
