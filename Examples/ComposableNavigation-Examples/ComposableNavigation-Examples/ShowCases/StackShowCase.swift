import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

/// This example showcases a stack of screens.
/// - Three counter screens + summary screen at the end.
/// - The StackNavigation state is a computed property
/// - Navigation to counter screens from summary screen
@Reducer
struct StackShowcase {
	
	// MARK: TCA
	
	enum Screen: Hashable {
		case counter(id: Counter.State.ID)
		case summary
	}
	
	@ObservableState
	struct State: Equatable {
		var currentScreen: Screen = .counter(id: 0)
		var counters: IdentifiedArrayOf<Counter.State> = .init(uniqueElements: (0..<3).map { Counter.State(id: $0) })
		
		var summary: Summary.State {
			get {
				.init(counters: counters)
			}
			set {
				counters = newValue.counters
			}
		}
		
		var stackNavigation: StackNavigation<Screen>.State {
			get {
				var screens = counters.ids.map(Screen.counter(id:))
				switch currentScreen {
				case .counter(let id):
					screens = Array(screens.prefix(id + 1))
				case .summary:
					screens = screens + [.summary]
				}
				return .init(items: screens)
			}
			set {
				currentScreen = newValue.items.last!
			}
		}
	}
	
	@CasePathable
	enum Action {
		case counter(IdentifiedActionOf<Counter>)
		case summary(Summary.Action)
		case stackNavigation(StackNavigation<Screen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case let .counter(.element(id, action: .done)):
			let nextId = id + 1
			if state.counters.ids.contains(nextId) {
				return .send(.stackNavigation(.pushItem(.counter(id: nextId))))
			} else {
				return .send(.stackNavigation(.pushItem(.summary)))
			}
		case .summary(.goTo(let id)):
			state.currentScreen = .counter(id: id)
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.summary, action: \.summary) {
			Summary()
		}
		Scope(state: \.stackNavigation, action: \.stackNavigation) {
			StackNavigation<Screen>()
		}
		Reduce(privateReducer)
			.forEach(\.counters, action: \.counter) {
				Counter()
			}
	}
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counter(let id):
				return CounterView(
					store: store.scope(
						state: { $0.counters[id: id]! },
						action: { Action.counter(.element(id: id, action:$0)) }
					)
				)
			case .summary:
				return SummaryView(
					store: store.scope(
						state: \.summary,
						action: \.summary
					)
				)
			}
		}
	}
	
	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		StackNavigationViewController(
			store: store.scope(
				state: \.stackNavigation,
				action: \.stackNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}

// MARK: Helper

extension StackShowcase {
	@Reducer
	struct Summary {
		@ObservableState
		struct State: Equatable {
			let counters: IdentifiedArrayOf<Counter.State>
		}
		
		@CasePathable
		enum Action {
			case goTo(id: Counter.State.ID)
		}
		
		func reduce(into state: inout State, action: Action) -> Effect<Action> {
			.none
		}
	}

	struct SummaryView: View, Presentable {
		let store: StoreOf<Summary>
		
		var body: some View {
			List {
				ForEach(store.counters) { counter in
					HStack {
						VStack(alignment: .leading) {
							Text("ID: \(counter.id)").font(.caption)
							Text("Count: \(counter.count)")
						}
						Spacer()
						Button("Go to screen") {
							store.send(.goTo(id: counter.id))
						}
						.buttonStyle(BorderlessButtonStyle())
					}
				}
			}
		}
	}
}
