import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

@Reducer
struct CountryList {
	@ObservableState
	struct State: Equatable {
		let countries: [Country]
	}
	
	@CasePathable
	enum Action {
		case selectCountry(id: Country.ID)
		case selectFilter
		case selectSorting
	}
}

struct CountryListView: View, Presentable {
	let store: StoreOf<CountryList>
	
	var body: some View {
		List {
			ForEach(store.countries) { country in
				Button(
					action: {
						store.send(.selectCountry(id: country.id))
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
						store.send(.selectSorting)
					},
					label: {
						Image(systemName: "arrow.up.arrow.down.circle").imageScale(.large)
					}
				)
			}
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(
					action: {
						store.send(.selectFilter)
					},
					label: {
						Image(systemName: "line.horizontal.3.decrease.circle").imageScale(.large)
					}
				)
			}
		}
	}
}
