import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryDeepLink: ReducerProtocol {
	
	// MARK: TCA
	
	struct State: Equatable, Codable {}
	
	enum Action: Equatable, Codable {
		case showCountry(Country.ID)
		case showSorting
		case showSortingReset
		case showAlertOptions
		case showNestedNavigation
	}
	
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
	
	static func makeView(store: Store<State, Action>) -> UIViewController {
		CountryDeepLinkView(store: store).viewController
	}
}

struct CountryDeepLinkView: View, Presentable {
	let store: Store<CountryDeepLink.State, CountryDeepLink.Action>
	
	var body: some View {
		NavigationView {
			Form {
				Button {
					ViewStore(store).send(.showCountry("Austria"))
				} label: {
					Label("Show Austria", systemImage: "list.dash")
				}
				Button {
					ViewStore(store).send(.showSorting)
				} label: {
					Label("Show sorting options", systemImage: "arrow.up.arrow.down.circle")
				}
				Button {
					ViewStore(store).send(.showSortingReset)
				} label: {
					Label("Show sorting options reset", systemImage: "arrow.up.arrow.down.circle")
				}
				Button {
					ViewStore(store).send(.showAlertOptions)
				} label: {
					Label("Show alert options", systemImage: "exclamationmark.bubble")
				}
				Button {
					ViewStore(store).send(.showNestedNavigation)
				} label: {
					Label("Nest multiple layers of stack and modal navigation", systemImage: "square.3.layers.3d.down.left")
				}
			}
			.navigationTitle("Deep link")
		}
	}
}
