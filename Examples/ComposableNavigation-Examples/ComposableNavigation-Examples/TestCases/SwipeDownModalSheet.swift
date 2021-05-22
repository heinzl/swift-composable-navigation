import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct SwipeDownModalSheet {
	
	// MARK: TCA
	
	enum Screen: String {
		case sheet
	}
	
	struct State: Equatable {
		var modalNavigation = ModalNavigation<Screen>.State()
	}
	
	enum Action: Equatable {
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	struct Environment {}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		ModalNavigation<Screen>.reducer()
			.pullback(
				state: \State.modalNavigation,
				action: /Action.modalNavigation,
				environment: { _ in () }
			)
	])
	
	// MARK: View creation
	
	struct RootView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				VStack(spacing: 20) {
					Button("Present") {
						viewStore.send(.modalNavigation(.presentSheet(.sheet)))
					}
					.accessibilityIdentifier("present")
					Text(modalText(state: viewStore.modalNavigation))
						.accessibilityIdentifier("modalStateRoot")
				}
			}
		}
	}
	
	struct SheetView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			WithViewStore(store) { viewStore in
				Text(modalText(state: viewStore.modalNavigation))
					.accessibilityIdentifier("modalStateSheet")
			}
		}
	}
	
	private static func modalText(state: ModalNavigation<Screen>.State) -> String {
		state.styledItem?.item.rawValue ?? "nil"
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .sheet:
				return SheetView(store: store)
			}
		}
	}
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController{
		UIHostingController(
			rootView: SwipeDownModalSheet.RootView(store: store)
		)
		.withModal(
			store: store.scope(
				state: \.modalNavigation,
				action: SwipeDownModalSheet.Action.modalNavigation
			),
			viewProvider: SwipeDownModalSheet.ViewProvider(
				store: store
			)
		)
	}
}
