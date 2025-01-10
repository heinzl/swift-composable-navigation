import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test
@Reducer
struct SwipeBackOnStackNavigation {
	
	// MARK: TCA
	
	enum Screen: String {
		case root
		case pushed
	}
	
	@ObservableState
	struct State: Equatable {
		var stackNavigation = StackNavigation<Screen>.State(items: [.root])
	}
	
	@CasePathable
	enum Action {
		case stackNavigation(StackNavigation<Screen>.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.stackNavigation, action: \.stackNavigation) {
			StackNavigation<Screen>()
		}
	}
	
	// MARK: View creation
	
	struct RootView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			VStack(spacing: 20) {
				Button("Push") {
					store.send(.stackNavigation(.pushItem(.pushed)))
				}
				.accessibilityIdentifier("push")
				Text(modalText(state: store.stackNavigation))
					.accessibilityIdentifier("stackStateRoot")
			}
		}
	}
	
	struct PushedView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			Text(modalText(state: store.stackNavigation))
				.accessibilityIdentifier("stackStatePushed")
		}
	}
	
	private static func modalText(state: StackNavigation<Screen>.State?) -> String {
		state?.topItem?.rawValue ?? "nil"
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .root:
				return RootView(store: store)
			case .pushed:
				return PushedView(store: store)
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
			viewProvider: SwipeBackOnStackNavigation.ViewProvider(
				store: store
			)
		)
	}
}

