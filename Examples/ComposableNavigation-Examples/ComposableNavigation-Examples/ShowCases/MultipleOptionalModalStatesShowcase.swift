import Foundation
import ComposableNavigation
import ComposableArchitecture
import SwiftUI

/// This example showcases how to model multiple optional states.
/// This can be necessary if you want to present modal screens without
/// keeping the modal state after dismissing it.
struct MultipleOptionalModalStatesShowcase {
	// MARK: TCA
	
	enum Screen: Hashable {
		case counterOne
		case counterTwo
	}
	
	enum ModalState: Equatable {
		case counterOne(Counter.State)
		case counterTwo(Counter.State)
	}
	
	struct State: Equatable {
		var modalState: ModalState?
		var selectedCount: Int?
		
		var selectedCountText: String {
			guard let selectedCount = selectedCount else {
				return "None"
			}
			return "\(selectedCount)"
		}
		
		var counterOne: Counter.State? {
			get { (/ModalState.counterOne).extract(from: modalState) }
			set { modalState = newValue.map { .counterOne($0) } }
		}
		
		var counterTwo: Counter.State? {
			get { (/ModalState.counterTwo).extract(from: modalState) }
			set { modalState = newValue.map { .counterTwo($0) } }
		}
		
		var modalNavigation: ModalNavigation<Screen>.State {
			get {
				let item: ModalNavigation<Screen>.StyledItem?
				switch modalState {
				case .counterOne:
					item = .init(item: .counterOne, style: .formSheet)
				case .counterTwo:
					item = .init(item: .counterTwo, style: .formSheet)
				case .none:
					item = nil
				}
				return .init(styledItem: item)
			}
			set {
				let modalState: ModalState?
				switch newValue.styledItem?.item {
				case .counterOne:
					modalState = .counterOne(.init(id: 1))
				case .counterTwo:
					modalState = .counterTwo(.init(id: 2))
				case .none:
					modalState = nil
				}
				self.modalState = modalState
			}
		}
	}
	
	enum Action: Equatable {
		case counterOne(Counter.Action)
		case counterTwo(Counter.Action)
		case modalNavigation(ModalNavigation<Screen>.Action)

		case showCounterOne
		case showCounterTwo
	}
	
	struct Environment {}
	
	private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .showCounterOne:
			return .task { .modalNavigation(.presentSheet(.counterOne)) }
		case .showCounterTwo:
			return .task { .modalNavigation(.presentSheet(.counterTwo)) }
		case .counterOne(.done):
			state.selectedCount = state.counterOne?.count
			return .task { .modalNavigation(.dismiss()) }
		case .counterTwo(.done):
			state.selectedCount = state.counterTwo?.count
			return .task { .modalNavigation(.dismiss()) }
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		Counter.reducer
			.optional()
			.pullback(
				state: \.counterOne,
				action: /Action.counterOne,
				environment: { _ in .init() }
			),
		Counter.reducer
			.optional()
			.pullback(
				state: \.counterTwo,
				action: /Action.counterTwo,
				environment: { _ in .init() }
			),
		ModalNavigation<Screen>.reducer()
			.pullback(
				state: \.modalNavigation,
				action: /Action.modalNavigation,
				environment: { _ in () }
			),
		privateReducer
	])
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counterOne:
				return store.scope(
					state: \.counterOne,
					action: Action.counterOne
				).compactMap(CounterView.init(store:)) ?? UIViewController()
			case .counterTwo:
				return store.scope(
					state: \.counterTwo,
					action: Action.counterTwo
				).compactMap(CounterView.init(store:)) ?? UIViewController()
			}
		}
	}

	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: MultipleOptionalModalStatesShowcaseView(store: store)
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


struct MultipleOptionalModalStatesShowcaseView: View, Presentable {
	let store: Store<MultipleOptionalModalStatesShowcase.State, MultipleOptionalModalStatesShowcase.Action>
	
	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			VStack {
				HStack {
					Button("Counter 1") {
						viewStore.send(.showCounterOne)
					}
					Button("Counter 2") {
						viewStore.send(.showCounterTwo)
					}
				}
				.padding()
				Text("Selected count: \(viewStore.selectedCountText)")
			}
		}
	}
}
