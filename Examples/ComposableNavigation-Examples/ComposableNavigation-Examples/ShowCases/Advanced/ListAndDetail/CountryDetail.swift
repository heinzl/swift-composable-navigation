import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryDetail {
	struct State: Equatable {
		let country: Country
	}

	enum Action: Equatable {}

	struct Environment {}
	
	static let reducer: Reducer<State, Action, Environment> = .empty
}

struct CountryDetailView: View, Presentable {
	let store: Store<CountryDetail.State, CountryDetail.Action>
	
	var body: some View {
		WithViewStore(store) { viewStore in
			List {
				Cell(label: "Name", value: viewStore.country.name)
				Cell(label: "Capital", value: viewStore.country.capital)
				Cell(label: "Continent", value: viewStore.country.continent)
			}
			.listStyle(InsetGroupedListStyle())
		}
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
