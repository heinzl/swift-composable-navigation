import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

struct Counter {
	struct State: Equatable, Identifiable {
		let id: Int
		var count: Int = 0
		var showDone = true
	}
	
	enum Action: Equatable {
		case up
		case down
		case done
	}
	
	struct Environment {}
	
	static let reducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .up:
			state.count += 1
		case .down:
			state.count -= 1
		case .done:
			break
		}
		return .none
	}
}

struct CounterView: View, Presentable {
	let store: Store<Counter.State, Counter.Action>
	
	var body: some View {
		WithViewStore(store) { viewStore in
			VStack {
				HStack {
					Button(action: {
						viewStore.send(.down)
					}) {
						Image(systemName: "chevron.down.circle")
					}
					Text("\(viewStore.count)")
						.font(.headline)
					Button(action: {
						viewStore.send(.up)
					}) {
						Image(systemName: "chevron.up.circle")
					}
				}
				.padding()
				if viewStore.showDone {
					Button("Done") {
						viewStore.send(.done)
					}
				}
			}
			.navigationTitle("ID: \(viewStore.id)")
		}
	}
}

struct CounterView_Previews: PreviewProvider {
	static var previews: some View {
		CounterView(store: Store(
			initialState: .init(id: 0),
			reducer: Counter.reducer,
			environment: .init()
		))
	}
}
