import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This example showcases multiple modal screens.
/// - Screens are presented using sheet and fullscreen style.
/// - Screens are dismissed automatically when another screen is presented.
/// - Modal sheet can be swiped down. Navigation state update automatically.
struct ModalShowcase {
	
	// MARK: TCA
	
	enum Screen: String {
		case counterOne
		case counterTwo
		case helper
	}
	
	struct State: Equatable {
		var counterOne = Counter.State(id: 1)
		var counterTwo = Counter.State(id: 2)
		var helper = Helper.State()
		
		var modalNavigation = ModalNavigation<Screen>.State()
	}
	
	enum Action: Equatable {
		case counterOne(Counter.Action)
		case counterTwo(Counter.Action)
		case helper(Helper.Action)
		
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	struct Environment {}
	
	private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .counterOne(.done), .counterTwo(.done):
			return .task { .modalNavigation(.dismiss()) }
		case .helper(.showCounterOne):
			return .task { .modalNavigation(.presentSheet(.counterOne)) }
		case .helper(.showCounterTwo):
			return .task { .modalNavigation(.presentFullScreen(.counterTwo)) }
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		Counter.reducer
			.pullback(
				state: \.counterOne,
				action: /Action.counterOne,
				environment: { _ in .init() }
			),
		Counter.reducer
			.pullback(
				state: \.counterTwo,
				action: /Action.counterTwo,
				environment: { _ in .init() }
			),
		Helper.reducer
			.pullback(
				state: \.helper,
				action: /Action.helper,
				environment: { _ in .init() }
			),
		ModalNavigation<Screen>.reducer()
			.pullback(
				state: \.modalNavigation,
				action: /Action.modalNavigation,
				environment: { _ in () }
			),
		privateReducer
	])
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counterOne:
				let view = CounterView(
					store: store.scope(
						state: \.counterOne,
						action: Action.counterOne
					)
				)
				let host = UIHostingController(rootView: view)
				host.view.backgroundColor = UIColor.red
				return host
			case .counterTwo:
				let view = CounterView(
					store: store.scope(
						state: \.counterTwo,
						action: Action.counterTwo
					)
				)
				let host = UIHostingController(rootView: view)
				host.view.backgroundColor = UIColor.green
				return host
			case .helper:
				return HelperView(
					store: store.scope(
						state: \.helper,
						action: Action.helper
					)
				)
			}
		}
	}

	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: ModalShowcaseView(store: store)
		)
		.withModal(
			store: store.scope(
				state: \.modalNavigation,
				action: Action.modalNavigation
			),
			viewProvider: ViewProvider(store: store)
		)
	}
}

struct ModalShowcaseView: View {
	let store: Store<ModalShowcase.State, ModalShowcase.Action>
	
	var body: some View {
		VStack(spacing: 20) {
			Button("Show counter 1 (red)\nusing sheet style") {
				ViewStore(store).send(.modalNavigation(.presentSheet(.counterOne)))
			}
			Button("Show counter 2 (green)\nusing fullscreen style") {
				ViewStore(store).send(.modalNavigation(.presentFullScreen(.counterTwo)))
			}
			
			Button("Show helper screen") {
				ViewStore(store).send(.modalNavigation(.presentSheet(.helper)))
			}
		}
	}
}

// MARK: Helper

extension ModalShowcase {
	struct Helper {
		struct State: Equatable {}
		
		enum Action: Equatable {
			case showCounterOne
			case showCounterTwo
		}
		
		struct Environment {}
		
		static let reducer: Reducer<State, Action, Environment> = Reducer.empty
	}
	
	struct HelperView: View, Presentable {
		let store: Store<Helper.State, Helper.Action>
		
		var body: some View {
			VStack(spacing: 20) {
				Button("Dismiss and show counter 1 (red)\nusing sheet style") {
					ViewStore(store).send(.showCounterOne)
				}
				Button("Dismiss and show counter 2 (green)\nusing fullscreen style") {
					ViewStore(store).send(.showCounterTwo)
				}
			}
		}
	}
}
