import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryDetail: Reducer {
	struct State: Equatable {
		let country: Country
	}

	enum Action: Equatable {}

	var body: some Reducer<State, Action> {
		EmptyReducer()
	}
}

struct CountryDetailView: View, Presentable {
	let store: Store<CountryDetail.State, CountryDetail.Action>
	
	var body: some View {
		WithViewStore(store, observe: \.country) { viewStore in
			List {
				Cell(label: "Name", value: viewStore.name)
				Cell(label: "Capital", value: viewStore.capital)
				Cell(label: "Continent", value: viewStore.continent)
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
