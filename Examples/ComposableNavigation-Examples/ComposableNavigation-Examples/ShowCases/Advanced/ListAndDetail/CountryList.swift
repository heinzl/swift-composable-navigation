import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryList: Reducer {
	struct State: Equatable {
		let countries: [Country]
	}

	enum Action: Equatable {
		case selectCountry(id: Country.ID)
		case selectFilter
		case selectSorting
	}
	
	func reduce(into state: inout State, action: Action) -> Effect<Action> {
		.none
	}
}

struct CountryListView: View, Presentable {
	let store: Store<CountryList.State, CountryList.Action>
	
	var body: some View {
		WithViewStore(store, observe: \.countries) { viewStore in
			List {
				ForEach(viewStore.state) { country in
					Button(
						action: {
							viewStore.send(.selectCountry(id: country.id))
						},
						label: {
							HStack {
								VStack(alignment: .leading) {
									Text(country.name)
									Text(country.capital)
										.font(.caption)
										.foregroundColor(.secondary)
								}
								Spacer()
								Image(systemName: "chevron.right")
									.font(.body)
									.foregroundColor(Color(UIColor.tertiaryLabel))
							}
						}
					)
				}
			}
			.navigationTitle("Countries")
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button(
						action: {
							viewStore.send(.selectSorting)
						},
						label: {
							Image(systemName: "arrow.up.arrow.down.circle").imageScale(.large)
						}
					)
				}
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(
						action: {
							viewStore.send(.selectFilter)
						},
						label: {
							Image(systemName: "line.horizontal.3.decrease.circle").imageScale(.large)
						}
					)
				}
			}
		}
	}
}
