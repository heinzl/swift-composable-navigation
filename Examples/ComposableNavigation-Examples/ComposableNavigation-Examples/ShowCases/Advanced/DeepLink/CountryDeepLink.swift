import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryDeepLink: ReducerProtocol {
	
	// MARK: TCA
	
	struct State: Equatable {}
	
	enum Action: Equatable {
		case showCountry(Country.ID)
		case showSorting
		case showSortingReset
		case showAlertOptions
	}
	
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
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
			}
			.navigationTitle("Deep link")
		}
	}
}
