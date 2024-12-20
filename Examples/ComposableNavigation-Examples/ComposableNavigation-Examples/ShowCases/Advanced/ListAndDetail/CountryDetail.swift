import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

@Reducer
struct CountryDetail {
	@ObservableState
	struct State: Equatable {
		let country: Country
	}

	@CasePathable
	enum Action {}
}

struct CountryDetailView: View, Presentable {
	let store: StoreOf<CountryDetail>
	
	var body: some View {
		List {
			Cell(label: "Name", value: store.country.name)
			Cell(label: "Capital", value: store.country.capital)
			Cell(label: "Continent", value: store.country.continent)
		}
		.listStyle(InsetGroupedListStyle())
	}
	
	struct Cell: View {
		let label: String
		let value: String
		
		var body: some View {
			HStack {
				Text(label)
					.font(.subheadline)
					.foregroundColor(.secondary)
				Spacer()
				Text(value)
					.font(.body)
					.foregroundColor(.primary)
			}
		}
	}
}
