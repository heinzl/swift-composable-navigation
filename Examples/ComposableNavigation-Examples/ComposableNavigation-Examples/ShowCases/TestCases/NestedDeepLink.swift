import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test

@Reducer
struct NestedModal {
	@ObservableState
	struct State: Equatable, Identifiable {
		let modalLevel: Int
		let stackLevel: Int
		
		var id: Int {
			stackLevel
		}
		
		var nestedStack: NestedStack.State?
		var modal: ModalNavigation<Int>.State {
			get {
				if let nestedStack {
					return .init(styledItem: .init(
						item: nestedStack.modalLevel,
						style: .pageSheet
					))
				} else {
					return .init(styledItem: nil)
				}
			}
			set {
				if let item = newValue.styledItem?.item {
					nestedStack = NestedStack.State(modalLevel: item)
				} else {
					nestedStack = nil
				}
			}
		}
	}
	
	@CasePathable
	enum Action {
		case pushTapped
		case presentTapped
		
		case nestedStack(NestedStack.Action)
		case modal(ModalNavigation<Int>.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.modal, action: \.modal) {
			ModalNavigation<Int>()
		}
		
		Reduce { state, action in
			switch action {
			case .presentTapped:
				let nextModalLevel = state.modalLevel + 1
				return .send(.modal(.presentSheet(nextModalLevel)))
			default:
				return .none
			}
		}
		.ifLet(\.nestedStack, action: \.nestedStack) {
			NestedStack()
		}
	}
	
	struct ContentView: View {
		let store: Store<State, Action>
		
		var body: some View {
			VStack(spacing: 8) {
				HStack {
					Text("Modal level:")
					Text("\(store.modalLevel)")
						.bold()
						.accessibilityIdentifier("modalLevel")
				}
				HStack {
					Text("Stack level:")
					Text("\(store.stackLevel)")
						.bold()
						.accessibilityIdentifier("stackLevel")
				}
				Button("Push") {
					store.send(.pushTapped)
				}
				Button("Present") {
					store.send(.presentTapped)
				}
			}
		}
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		UIHostingController(rootView: ContentView(store: store))
			.withModal(
				store: store.scope(
					state: \.modal,
					action: \.modal
				),
				viewProvider: ViewProvider(store: store)
			)
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Int) -> Presentable {
			return store.scope(
				state: \.nestedStack,
				action: \.nestedStack
			)
			.compactMap(NestedStack.makeView(store:)) ?? UIViewController()
		}
	}
}

@Reducer
struct NestedStack {
	@ObservableState
	struct State: Equatable {
		let modalLevel: Int
		
		init(modalLevel: Int, nestedModals: IdentifiedArrayOf<NestedModal.State>? = nil) {
			self.modalLevel = modalLevel
			self.nestedModals = nestedModals ?? [.init(modalLevel: modalLevel, stackLevel: 1)]
		}
		
		var nestedModals: IdentifiedArrayOf<NestedModal.State>
		var stack: StackNavigation<Int>.State {
			get {
				.init(items: nestedModals.map(\.stackLevel))
			}
			set {
				nestedModals = .init(
					uniqueElements: newValue.items.map { NestedModal.State(modalLevel: modalLevel, stackLevel: $0) }
				)
			}
		}
	}
	
	@CasePathable
	indirect enum Action {
		case nestedModal(IdentifiedActionOf<NestedModal>)
		case stack(StackNavigation<Int>.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.stack, action: \.stack) {
			StackNavigation<Int>()
		}
		
		Reduce { state, action in
			switch action {
			case .nestedModal(.element(id: _, action: .pushTapped)):
				let nextStackLevel = state.nestedModals.last!.stackLevel + 1
				return .send(.stack(.pushItem(nextStackLevel)))
			default:
				return .none
			}
		}
		.forEach(\.nestedModals, action: \.nestedModal) {
			NestedModal()
		}
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		StackNavigationViewController(
			store: store.scope(
				state: \.stack,
				action: \.stack
			),
			viewProvider: ViewProvider(store: store)
		)
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Int) -> Presentable {
			let cacheElement = store.withState { $0.nestedModals[id: navigationItem]! }
			return NestedModal.makeView(store: store.scope(
				state: { $0.nestedModals[id: navigationItem] ?? cacheElement },
				action: { Action.nestedModal(.element(id: navigationItem, action: $0)) }
			))
		}
	}
}
