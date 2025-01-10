import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This example showcases a UIAlertController
/// - Send TCA action from UIAlertAction
@Reducer
struct AlertShowcase {
	
	// MARK: TCA
	
	enum Screen: String {
		case resetAlert
	}
	
	@ObservableState
	struct State: Equatable {
		var counter = Counter.State(id: 1, showDone: false)
		var modalNavigation = ModalNavigation<Screen>.State()
		
		var isResetButtonDisabled: Bool {
			counter.count == 0
		}
	}
	
	@CasePathable
	enum Action {
		case counter(Counter.Action)
		case resetCounter
		
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .resetCounter:
			state.counter.count = 0
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.counter, action: \.counter) {
			Counter()
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
					toNavigationCasePath: \.modalNavigation
				))
				alert.addAction(UIAlertAction(
					title: "Reset",
					style: .destructive,
					action: .resetCounter,
					store: store,
					toNavigationCasePath: \.modalNavigation
				))
				return alert
			}
		}
	}

	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: AlertShowcaseView(store: store)
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

struct AlertShowcaseView: View {
	let store: Store<AlertShowcase.State, AlertShowcase.Action>
	
	var body: some View {
		VStack(spacing: 20) {
			CounterView(store: store.scope(
				state: \.counter,
				action: \.counter
			))
			Button("Reset counter to 0") {
				store.send(.modalNavigation(.presentFullScreen(.resetAlert)))
			}
			.disabled(store.isResetButtonDisabled)
		}
	}
}
