import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct AlertPlayground {
	
	// MARK: TCA
	
	enum ModalScreen: Hashable {
		case resetAlert
		case actionSheet
	}
	
	struct State: Equatable {
		static let initialCount = 5
		
		var counter = Counter.State(id: 0, count: Self.initialCount)
		var alertNavigation = ModalNavigation<ModalScreen>.State()
		
		var isResetDisabled: Bool {
			counter.count == Self.initialCount
		}
	}
	
	enum Action: Equatable {
		case counter(Counter.Action)
		case resetCounter
		case alertNavigation(ModalNavigation<ModalScreen>.Action)
	}
	
	struct Environment {}
	
	private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .resetCounter:
			state.counter.count = State.initialCount
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		ModalNavigation<ModalScreen>.reducer()
			.pullback(
				state: \.alertNavigation,
				action: /Action.alertNavigation,
				environment: { _ in () }
			),
		Counter.reducer
			.pullback(
				state: \.counter,
				action: /Action.counter,
				environment: { _ in .init() }
			),
		privateReducer
	])
	
	// MARK: View creation
	
	struct ModalViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: ModalScreen) -> Presentable {
			let viewStore = ViewStore(store)
			switch navigationItem {
			case .resetAlert:
				let alert = UIAlertController(
					title: "Warning",
					message: "Reset counter?",
					preferredStyle: .alert
				)
				alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in
					viewStore.send(.alertNavigation(.dismiss))
				}))
				alert.addAction(.init(title: "Reset", style: .destructive, handler: { _ in
					viewStore.send(.alertNavigation(.dismiss))
					viewStore.send(.resetCounter)
				}))
				return alert
			case .actionSheet:
				let alert = UIAlertController(
					title: "Choose from following options:",
					message: nil,
					preferredStyle: .actionSheet
				)
				alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in
					viewStore.send(.alertNavigation(.dismiss))
				}))
				alert.addAction(.init(title: "Up", style: .default, handler: { _ in
					viewStore.send(.alertNavigation(.dismiss))
					viewStore.send(.counter(.up))
				}))
				alert.addAction(.init(title: "Down", style: .default, handler: { _ in
					viewStore.send(.alertNavigation(.dismiss))
					viewStore.send(.counter(.down))
				}))
				let resetAction = UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
					viewStore.send(.alertNavigation(.dismiss))
					viewStore.send(.alertNavigation(.presentFullScreen(.resetAlert)))
				})
				resetAction.isEnabled = !viewStore.isResetDisabled
				alert.addAction(resetAction)
				return alert
			}
		}
	}
}

struct AlertPlaygroundView: View, Presentable {
	let store: Store<AlertPlayground.State, AlertPlayground.Action>

	var body: some View {
		WithViewStore(store) { viewStore in
			VStack {
				Text("Count: \(viewStore.counter.count)")
					.font(.largeTitle)
					.padding()
				
				Button("Options") {
					viewStore.send(.alertNavigation(.presentFullScreen(.actionSheet)))
				}
				.padding()
				
				Button("Reset") {
					viewStore.send(.alertNavigation(.presentFullScreen(.resetAlert)))
				}
				.disabled(viewStore.isResetDisabled)
				.padding()
			}
		}
	}
}
