import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test

struct NestedModal: Reducer {
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
	
	enum Action: Equatable {
		case pushTapped
		case presentTapped
		
		case nestedStack(NestedStack.Action)
		case modal(ModalNavigation<Int>.Action)
	}
	
	var body: some Reducer<State, Action> {
		Scope(state: \.modal, action: /Action.modal) {
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
		.ifLet(\.nestedStack, action: /Action.nestedStack) {
			NestedStack()
		}
	}
	
	struct ContentView: View {
		let store: Store<State, Action>
		
		var body: some View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: 8) {
					HStack {
						Text("Modal level:")
						Text("\(viewStore.modalLevel)")
							.bold()
							.accessibilityIdentifier("modalLevel")
					}
					HStack {
						Text("Stack level:")
						Text("\(viewStore.stackLevel)")
							.bold()
							.accessibilityIdentifier("stackLevel")
					}
					Button("Push") {
						viewStore.send(.pushTapped)
					}
					Button("Present") {
						viewStore.send(.presentTapped)
					}
				}
			}
		}
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		UIHostingController(rootView: ContentView(store: store))
			.withModal(
				store: store.scope(state: \.modal, action: Action.modal),
				viewProvider: ViewProvider(store: store)
			)
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Int) -> Presentable {
			return store.scope(
				state: \.nestedStack,
				action: Action.nestedStack
			)
			.compactMap(NestedStack.makeView(store:)) ?? UIViewController()
		}
	}
}

struct NestedStack: Reducer {
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
	
	indirect enum Action: Equatable {
		case nestedModal(id: NestedModal.State.ID, action: NestedModal.Action)
		case stack(StackNavigation<Int>.Action)
	}
	
	var body: some Reducer<State, Action> {
		Scope(state: \.stack, action: /Action.stack) {
			StackNavigation<Int>()
		}
		
		Reduce { state, action in
			switch action {
			case .nestedModal(_, .pushTapped):
				let nextStackLevel = state.nestedModals.last!.stackLevel + 1
				return .send(.stack(.pushItem(nextStackLevel)))
			default:
				return .none
			}
		}
		.forEach(\.nestedModals, action: /Action.nestedModal(id:action:)) {
			NestedModal()
		}
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		StackNavigationViewController(
			store: store.scope(state: \.stack, action: Action.stack),
			viewProvider: ViewProvider(store: store)
		)
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Int) -> Presentable {
			let cacheElement = store.withState { $0.nestedModals[id: navigationItem]! }
			return NestedModal.makeView(store: store.scope(
				state: { $0.nestedModals[id: navigationItem] ?? cacheElement },
				action: { Action.nestedModal(id: navigationItem, action: $0) }
			))
		}
	}
}
