import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This example showcases a UIAlertController
/// - Send TCA action from UIAlertAction
struct AlertShowcase: ReducerProtocol {
	
	// MARK: TCA
	
	enum Screen: String {
		case resetAlert
	}
	
	struct State: Equatable {
		var counter = Counter.State(id: 1, showDone: false)
		var modalNavigation = ModalNavigation<Screen>.State()
		
		var isResetButtonDisabled: Bool {
			counter.count == 0
		}
	}
	
	enum Action: Equatable {
		case counter(Counter.Action)
		case resetCounter
		
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .resetCounter:
			state.counter.count = 0
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerProtocol<State, Action> {
		Scope(state: \.counter, action: /Action.counter) {
			Counter()
		}
		Scope(state: \.modalNavigation, action: /Action.modalNavigation) {
			ModalNavigation<Screen>()
		}
		Reduce(privateReducer(state:action:))
	}
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .resetAlert:
				let alert = UIAlertController(
					title: "Warning",
					message: "Reset counter?",
					preferredStyle: .alert
				)
				alert.addAction(UIAlertAction(
					title: "Cancel",
					style: .cancel,
					action: nil,
					store: store,
					toNavigationAction: Action.modalNavigation
				))
				alert.addAction(UIAlertAction(
					title: "Reset",
					style: .destructive,
					action: .resetCounter,
					store: store,
					toNavigationAction: Action.modalNavigation
				))
				return alert
			}
		}
	}

	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: AlertShowcaseView(store: store)
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

struct AlertShowcaseView: View {
	let store: Store<AlertShowcase.State, AlertShowcase.Action>
	
	var body: some View {
		WithViewStore(store, observe: \.isResetButtonDisabled) { viewStore in
			VStack(spacing: 20) {
				CounterView(store: store.scope(state: \.counter, action: AlertShowcase.Action.counter))
				Button("Reset counter to 0") {
					viewStore.send(.modalNavigation(.presentFullScreen(.resetAlert)))
				}
				.disabled(viewStore.state)
			}
		}
	}
}
