import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

@Reducer
struct Counter {
	@ObservableState
	struct State: Equatable, Identifiable {
		let id: Int
		var count: Int = 0
		var showDone = true
	}
	
	@CasePathable
	enum Action {
		case up
		case down
		case done
	}
	
	func reduce(into state: inout State, action: Action) -> Effect<Action> {
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
	let store: StoreOf<Counter>
	
	var body: some View {
		VStack {
			HStack {
				Button(action: {
					store.send(.down)
				}) {
					Image(systemName: "chevron.down.circle")
				}
				Text("\(store.count)")
					.font(.headline)
				Button(action: {
					store.send(.up)
				}) {
					Image(systemName: "chevron.up.circle")
				}
			}
			.padding()
			if store.showDone {
				Button("Done") {
					store.send(.done)
				}
			}
		}
		.navigationTitle("ID: \(store.id)")
	}
}

struct CounterView_Previews: PreviewProvider {
	static var previews: some View {
		CounterView(store: Store(
			initialState: Counter.State(id: 0),
			reducer: { Counter() }
		))
	}
}
