import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test
@Reducer
struct SwipeDownModalSheet {
	
	// MARK: TCA
	
	enum Screen: String {
		case sheet
	}
	
	@ObservableState
	struct State: Equatable {
		var modalNavigation = ModalNavigation<Screen>.State()
	}
	
	@CasePathable
	enum Action {
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.modalNavigation, action: \.modalNavigation) {
			ModalNavigation<Screen>()
		}
	}
	
	// MARK: View creation
	
	struct RootView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			VStack(spacing: 20) {
				Button("Present") {
					store.send(.modalNavigation(.presentSheet(.sheet)))
				}
				.accessibilityIdentifier("present")
				Text(modalText(state: store.modalNavigation))
					.accessibilityIdentifier("modalStateRoot")
			}
		}
	}
	
	struct SheetView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			Text(modalText(state: store.modalNavigation))
				.accessibilityIdentifier("modalStateSheet")
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
	
	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: SwipeDownModalSheet.RootView(store: store)
		)
		.withModal(
			store: store.scope(
				state: \.modalNavigation,
				action: \.modalNavigation
			),
			viewProvider: SwipeDownModalSheet.ViewProvider(
				store: store
			)
		)
	}
}
