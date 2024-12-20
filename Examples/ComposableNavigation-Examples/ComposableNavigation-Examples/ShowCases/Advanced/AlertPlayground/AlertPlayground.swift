import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

@Reducer
struct AlertPlayground {
	
	// MARK: TCA
	
	enum ModalScreen: Hashable {
		case resetAlert
		case actionSheet
	}
	
	@ObservableState
	struct State: Equatable {
		static let initialCount = 5
		
		var counter = Counter.State(id: 0, count: Self.initialCount)
		var alertNavigation = ModalNavigation<ModalScreen>.State()
		
		var isResetDisabled: Bool {
			counter.count == Self.initialCount
		}
	}
	
	@CasePathable
	enum Action {
		case counter(Counter.Action)
		case resetCounter
		case alertNavigation(ModalNavigation<ModalScreen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .resetCounter:
			state.counter.count = State.initialCount
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.alertNavigation, action: \.alertNavigation) {
			ModalNavigation<ModalScreen>()
		}
		Scope(state: \.counter, action: \.counter) {
			Counter()
		}
		Reduce(privateReducer)
	}
	
	// MARK: View creation
	
	struct ModalViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: ModalScreen) -> Presentable {
			switch navigationItem {
			case .resetAlert:
				let alert = UIAlertController(
					title: "Warning",
					message: "Reset counter?",
					preferredStyle: .alert
				)
				alert.addAction(makeAction(
					title: "Cancel",
					style: .cancel,
					action: nil
				))
				alert.addAction(makeAction(
					title: "Reset",
					style: .destructive,
					action: .resetCounter
				))
				return alert
				
			case .actionSheet:
				let alert = UIAlertController(
					title: "Choose from following options:",
					message: nil,
					preferredStyle: .actionSheet
				)
				alert.addAction(makeAction(
					title: "Cancel",
					style: .cancel,
					action: nil
				))
				alert.addAction(makeAction(
					title: "Up",
					style: .default,
					action: .counter(.up)
				))
				alert.addAction(makeAction(
					title: "Down",
					style: .default,
					action: .counter(.down)
				))
				let resetAction = makeAction(
					title: "Reset",
					style: .destructive,
					action: .alertNavigation(.presentFullScreen(.resetAlert))
				)
				resetAction.isEnabled = !store.withState({ $0.isResetDisabled })
				alert.addAction(resetAction)
				return alert
			}
		}
		
		private func makeAction(title: String, style: UIAlertAction.Style, action: Action?) -> UIAlertAction {
			UIAlertAction(
				title: title,
				style: style,
				action: action,
				store: store,
				toNavigationCasePath: \.alertNavigation
			)
		}
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		AlertPlaygroundView(store: store).viewController
			.withModal(
				store: store.scope(
					state: \.alertNavigation,
					action: \.alertNavigation
				),
				viewProvider: AlertPlayground.ModalViewProvider(store: store)
			)
	}
}

struct AlertPlaygroundView: View, Presentable {
	let store: StoreOf<AlertPlayground>

	var body: some View {
		VStack {
			Text("Count: \(store.counter.count)")
				.font(.largeTitle)
				.padding()
			
			Button("Options") {
				store.send(.alertNavigation(.presentFullScreen(.actionSheet)))
			}
			.padding()
			
			Button("Reset") {
				store.send(.alertNavigation(.presentFullScreen(.resetAlert)))
			}
			.disabled(store.isResetDisabled)
			.padding()
		}
	}
}
