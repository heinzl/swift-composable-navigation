import Foundation
import ComposableNavigation
import ComposableArchitecture
import UIKit

/// This showcase illustrates how two sub-components can be combined
/// in a single stack i.e. StackNavigationViewController
///
/// `CombiningStacksShowCase` hosts two `IndividualStack` features.
/// `CombiningStacksShowCase.stackNavigation` is a computed property
/// which concatenates `stack1` with `stack2`.
///
/// The reducer glues the two stacks together by adding the transition from
/// `stack1` to `stack2`.
///
/// `ViewProviding` is implemented by forwarding the call to
/// the respective sub-stack. `ViewProviding.Item` is wrapping the items
/// of respective the sub-stacks as well.
struct CombiningStacksShowCase: Reducer {
	struct State: Equatable {
		var stack1: IndividualStack.State
		var stack2: IndividualStack.State
		
		var stackNavigation: StackNavigation<CombinedScreen>.State {
			get {
				.init(items: stack1.stackNavigation.items.map(CombinedScreen.stack1) +
					  stack2.stackNavigation.items.map(CombinedScreen.stack2)
				)
			}
			set {
				stack1.stackNavigation.items = newValue.items.compactMap { $0.stack1Item }
				stack2.stackNavigation.items = newValue.items.compactMap { $0.stack2Item }
			}
		}
		
		init() {
			self.stack1 = .init(count1: -1, count2: -2, screens: [])
			self.stack2 = .init(count1: 1, count2: 2, screens: [])
			
			self.stackNavigation.items = [.stack1(.counter1)]
		}
	}
	
	enum Action: Equatable {
		case stackNavigation(StackNavigation<CombinedScreen>.Action)
		case stack1(IndividualStack.Action)
		case stack2(IndividualStack.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .stack1(.counter2(.done)):
			return .send(.stackNavigation(.pushItem(.stack2(.counter1))))
			
		default:
			return .none
		}
	}
	
	var body: some Reducer<State, Action> {
		Scope(state: \.stack1, action: /Action.stack1) {
			IndividualStack()
		}
		Scope(state: \.stack2, action: /Action.stack2) {
			IndividualStack()
		}
		Scope(state: \.stackNavigation, action: /Action.stackNavigation) {
			StackNavigation<CombinedScreen>()
		}
		Reduce(privateReducer)
	}
	
	enum CombinedScreen: Hashable {
		case stack1(IndividualStack.Screen)
		case stack2(IndividualStack.Screen)
	}
	
	struct CombinedViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: CombinedScreen) -> Presentable {
			switch navigationItem {
			case .stack1(let screen):
				return IndividualStack.ViewProvider(
					store: store.scope(state: \.stack1, action: Action.stack1)
				)
				.makePresentable(for: screen)
			case .stack2(let screen):
				return IndividualStack.ViewProvider(
					store: store.scope(state: \.stack2, action: Action.stack2)
				)
				.makePresentable(for: screen)
			}
		}
	}
	
	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		StackNavigationViewController(
			store: store.scope(
				state: \.stackNavigation,
				action: Action.stackNavigation
			),
			viewProvider: CombinedViewProvider(store: store)
		)
	}
}

extension CombiningStacksShowCase.CombinedScreen {
	var stack1Item: CombiningStacksShowCase.IndividualStack.Screen? {
		switch self {
		case .stack1(let screen):
			return screen
		default:
			return nil
		}
	}
	
	var stack2Item: CombiningStacksShowCase.IndividualStack.Screen? {
		switch self {
		case .stack2(let screen):
			return screen
		default:
			return nil
		}
	}
}

// MARK: CounterStack

extension CombiningStacksShowCase {
	struct IndividualStack: Reducer {
		struct State: Equatable {
			var counter1: Counter.State
			var counter2: Counter.State
			
			var stackNavigation: StackNavigation<Screen>.State
			
			init(
				count1: Int = 100,
				count2: Int = 200,
				screens: [Screen] = [.counter1]
			) {
				self.counter1 = .init(id: 1, count: count1)
				self.counter2 = .init(id: 2, count: count2)
				self.stackNavigation = .init(items: screens)
			}
		}
		
		enum Action: Equatable {
			case stackNavigation(StackNavigation<Screen>.Action)
			case counter1(Counter.Action)
			case counter2(Counter.Action)
		}
		
		private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
			switch action {
			case .counter1(.done):
				return .send(.stackNavigation(.pushItem(.counter2)))
			default:
				return .none
			}
		}
		
		var body: some Reducer<State, Action> {
			Scope(state: \.counter1, action: /Action.counter1) {
				Counter()
			}
			Scope(state: \.counter2, action: /Action.counter2) {
				Counter()
			}
			Scope(state: \.stackNavigation, action: /Action.stackNavigation) {
				StackNavigation<Screen>()
			}
			Reduce(privateReducer)
		}
		
		enum Screen: Hashable {
			case counter1
			case counter2
		}
		
		struct ViewProvider: ViewProviding {
			let store: Store<State, Action>
			
			func makePresentable(for navigationItem: Screen) -> Presentable {
				switch navigationItem {
				case .counter1:
					return CounterView(
						store: store.scope(
							state: \.counter1,
							action: Action.counter1
						)
					)
				case .counter2:
					return CounterView(
						store: store.scope(
							state: \.counter2,
							action: Action.counter2
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
					action: Action.stackNavigation
				),
				viewProvider: ViewProvider(store: store)
			)
		}
	}
}
