import Foundation
import ComposableArchitecture
import ComposableNavigation
import SwiftUI

/// This example showcases a stack of screens.
/// - Three counter screens + summary screen at the end.
/// - The StackNavigation state is a computed property
/// - Navigation to counter screens from summary screen
struct StackShowcase {
	
	// MARK: TCA
	
	enum Screen: Hashable {
		case counter(id: Counter.State.ID)
		case summary
	}
	
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
	
	enum Action: Equatable {
		case counter(id: Counter.State.ID, action: Counter.Action)
		case summary(Summary.Action)
		case stackNavigation(StackNavigation<Screen>.Action)
	}
	
	struct Environment {}
	
	private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case let .counter(id, .done):
			let nextId = id + 1
			if state.counters.ids.contains(nextId) {
				return Effect(value: .stackNavigation(.pushItem(.counter(id: nextId))))
			} else {
				return Effect(value: .stackNavigation(.pushItem(.summary)))
			}
		case .summary(.goTo(let id)):
			state.currentScreen = .counter(id: id)
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		Counter.reducer.forEach(
			state: \.counters,
			action: /Action.counter(id:action:),
			environment: { _ in .init()}
		),
		Summary.reducer
			.pullback(
				state: \.summary,
				action: /Action.summary,
				environment: { _ in .init() }
			),
		StackNavigation<Screen>.reducer()
			.pullback(
				state: \.stackNavigation,
				action: /Action.stackNavigation,
				environment: { _ in () }
			),
		privateReducer
	])
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counter(let id):
				return CounterView(
					store: store.scope(
						state: { $0.counters[id: id]! },
						action: { Action.counter(id: id, action:$0) }
					)
				)
			case .summary:
				return SummaryView(
					store: store.scope(
						state: \.summary,
						action: Action.summary
					)
				)
			}
		}
	}
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		StackNavigationViewController(
			store: store.scope(
				state: \.stackNavigation,
				action: Action.stackNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}

// MARK: Helper

extension StackShowcase {
	struct Summary {
		struct State: Equatable {
			let counters: IdentifiedArrayOf<Counter.State>
		}
		
		enum Action: Equatable {
			case goTo(id: Counter.State.ID)
		}
		
		struct Environment {}
		
		static let reducer: Reducer<State, Action, Environment> = Reducer.empty
	}

	struct SummaryView: View, Presentable {
		let store: Store<Summary.State, Summary.Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				List {
					ForEach(viewStore.counters) { counter in
						HStack {
							VStack(alignment: .leading) {
								Text("ID: \(counter.id)").font(.caption)
								Text("Count: \(counter.count)")
							}
							Spacer()
							Button("Go to screen") {
								viewStore.send(.goTo(id: counter.id))
							}
							.buttonStyle(BorderlessButtonStyle())
						}
					}
				}
			}
		}
	}
}
