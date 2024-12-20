import Foundation
import ComposableNavigation
import ComposableArchitecture
import SwiftUI

/// This example showcases how to model multiple optional states.
/// This can be necessary if you want to present modal screens without
/// keeping the modal state after dismissing it.
@Reducer
struct MultipleOptionalModalStatesShowcase {
	// MARK: TCA
	
	enum Screen: Hashable {
		case counterOne
		case counterTwo
	}
	
	@CasePathable
	enum ModalState: Equatable {
		case counterOne(Counter.State)
		case counterTwo(Counter.State)
	}
	
	@ObservableState
	struct State: Equatable {
		var modalState: ModalState?
		var selectedCount: Int?
		
		var selectedCountText: String {
			guard let selectedCount else {
				return "None"
			}
			return "\(selectedCount)"
		}
		
		var counterOne: Counter.State? {
			get {
				guard let modalState else { return nil }
				return ModalState.allCasePaths.counterOne.extract(from: modalState)
			}
			set {
				modalState = newValue.map { .counterOne($0) }
			}
		}
		
		var counterTwo: Counter.State? {
			get {
				guard let modalState else { return nil }
				return ModalState.allCasePaths.counterTwo.extract(from: modalState)
			}
			set {
				modalState = newValue.map { .counterTwo($0) }
			}
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
	
	@CasePathable
	enum Action {
		case counterOne(Counter.Action)
		case counterTwo(Counter.Action)
		case modalNavigation(ModalNavigation<Screen>.Action)

		case showCounterOne
		case showCounterTwo
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .showCounterOne:
			return .send(.modalNavigation(.presentSheet(.counterOne)))
		case .showCounterTwo:
			return .send(.modalNavigation(.presentSheet(.counterTwo)))
		case .counterOne(.done):
			state.selectedCount = state.counterOne?.count
			return .send(.modalNavigation(.dismiss()))
		case .counterTwo(.done):
			state.selectedCount = state.counterTwo?.count
			return .send(.modalNavigation(.dismiss()))
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.modalNavigation, action: \.modalNavigation) {
			ModalNavigation<Screen>()
		}
		Reduce(privateReducer)
			.ifLet(\.counterOne, action: \.counterOne) {
				Counter()
			}
			.ifLet(\.counterTwo, action: \.counterTwo) {
				Counter()
			}
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .counterOne:
				return store.scope(
					state: \.counterOne,
					action: \.counterOne
				).compactMap(CounterView.init(store:)) ?? UIViewController()
			case .counterTwo:
				return store.scope(
					state: \.counterTwo,
					action: \.counterTwo
				).compactMap(CounterView.init(store:)) ?? UIViewController()
			}
		}
	}

	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		UIHostingController(
			rootView: MultipleOptionalModalStatesShowcaseView(store: store)
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


struct MultipleOptionalModalStatesShowcaseView: View, Presentable {
	let store: StoreOf<MultipleOptionalModalStatesShowcase>
	
	var body: some View {
		VStack {
			HStack {
				Button("Counter 1") {
					store.send(.showCounterOne)
				}
				Button("Counter 2") {
					store.send(.showCounterTwo)
				}
			}
			.padding()
			Text("Selected count: \(store.selectedCountText)")
		}
	}
}
