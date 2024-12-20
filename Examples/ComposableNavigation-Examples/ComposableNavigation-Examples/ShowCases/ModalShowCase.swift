import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This example showcases multiple modal screens.
/// - Screens are presented using sheet and fullscreen style.
/// - Screens are dismissed automatically when another screen is presented.
/// - Modal sheet can be swiped down. Navigation state update automatically.
@Reducer
struct ModalShowcase {
	
	// MARK: TCA
	
	enum Screen: String {
		case counterOne
		case counterTwo
		case helper
	}
	
	@ObservableState
	struct State: Equatable {
		var counterOne = Counter.State(id: 1)
		var counterTwo = Counter.State(id: 2)
		var helper = Helper.State()
		
		var modalNavigation = ModalNavigation<Screen>.State()
	}
	
	@CasePathable
	enum Action {
		case counterOne(Counter.Action)
		case counterTwo(Counter.Action)
		case helper(Helper.Action)
		
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .counterOne(.done), .counterTwo(.done):
			return .send(.modalNavigation(.dismiss()))
		case .helper(.showCounterOne):
			return .send(.modalNavigation(.presentSheet(.counterOne)))
		case .helper(.showCounterTwo):
			return .send(.modalNavigation(.presentFullScreen(.counterTwo)))
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.counterOne, action: \.counterOne) {
			Counter()
		}
		Scope(state: \.counterTwo, action: \.counterTwo) {
			Counter()
		}
		Scope(state: \.helper, action: \.helper) {
			Helper()
		}
		Scope(state: \.modalNavigation, action: \.modalNavigation) {
			ModalNavigation<Screen>()
		}
		Reduce(privateReducer)
	}
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counterOne:
				let view = CounterView(
					store: store.scope(
						state: \.counterOne,
						action: \.counterOne
					)
				)
				let host = UIHostingController(rootView: view)
				host.view.backgroundColor = UIColor.red
				return host
			case .counterTwo:
				let view = CounterView(
					store: store.scope(
						state: \.counterTwo,
						action: \.counterTwo
					)
				)
				let host = UIHostingController(rootView: view)
				host.view.backgroundColor = UIColor.green
				return host
			case .helper:
				return HelperView(
					store: store.scope(
						state: \.helper,
						action: \.helper
					)
				)
			}
		}
	}

	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: ModalShowcaseView(store: store)
		)
		.withModal(
			store: store.scope(
				state: \.modalNavigation,
				action: \.modalNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}

struct ModalShowcaseView: View {
	let store: StoreOf<ModalShowcase>
	
	var body: some View {
		VStack(spacing: 20) {
			Button("Show counter 1 (red)\nusing sheet style") {
				store.send(.modalNavigation(.presentSheet(.counterOne)))
			}
			Button("Show counter 2 (green)\nusing fullscreen style") {
				store.send(.modalNavigation(.presentFullScreen(.counterTwo)))
			}
			
			Button("Show helper screen") {
				store.send(.modalNavigation(.presentSheet(.helper)))
			}
		}
	}
}

// MARK: Helper

extension ModalShowcase {
	@Reducer
	struct Helper {
		struct State: Equatable {}
		
		@CasePathable
		enum Action {
			case showCounterOne
			case showCounterTwo
		}
	}
	
	struct HelperView: View, Presentable {
		let store: StoreOf<Helper>
		
		var body: some View {
			VStack(spacing: 20) {
				Button("Dismiss and show counter 1 (red)\nusing sheet style") {
					store.send(.showCounterOne)
				}
				Button("Dismiss and show counter 2 (green)\nusing fullscreen style") {
					store.send(.showCounterTwo)
				}
			}
		}
	}
}
