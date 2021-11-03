import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test
struct SwipeBackOnStackNavigation {
	
	// MARK: TCA
	
	enum Screen: String {
		case root
		case pushed
	}
	
	struct State: Equatable {
		var stackNavigation = StackNavigation<Screen>.State(items: [.root])
	}
	
	enum Action: Equatable {
		case stackNavigation(StackNavigation<Screen>.Action)
	}
	
	struct Environment {}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		StackNavigation<Screen>.reducer()
			.pullback(
				state: \State.stackNavigation,
				action: /Action.stackNavigation,
				environment: { _ in () }
			)
	])
	
	// MARK: View creation
	
	struct RootView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				VStack(spacing: 20) {
					Button("Push") {
						viewStore.send(.stackNavigation(.pushItem(.pushed)))
					}
					.accessibilityIdentifier("push")
					Text(modalText(state: viewStore.stackNavigation))
						.accessibilityIdentifier("stackStateRoot")
				}
			}
		}
	}
	
	struct PushedView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				Text(modalText(state: viewStore.stackNavigation))
					.accessibilityIdentifier("stackStatePushed")
			}
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
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		StackNavigationViewController(
			store: store.scope(
				state: \.stackNavigation,
				action: SwipeBackOnStackNavigation.Action.stackNavigation
			),
			viewProvider: SwipeBackOnStackNavigation.ViewProvider(
				store: store
			)
		)
	}
}

