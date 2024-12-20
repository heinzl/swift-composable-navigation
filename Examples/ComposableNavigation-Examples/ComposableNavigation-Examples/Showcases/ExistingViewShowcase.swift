import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture
import Combine

/// This example showcases how to reuse an already existing UIViewController subclass
/// by using a `NavigationHandler` in this case a `ModalNavigationHandler`
@Reducer
struct ExistingViewShowcase {
	
	// MARK: TCA
	
	enum Screen: String {
		case optionSelection
	}
	
	@ObservableState
	struct State: Equatable {
		var selectedOption: Option?
		var modalNavigation = ModalNavigation<Screen>.State()
	}
	
	@CasePathable
	enum Action {
		case optionSelected(Option)
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .optionSelected(let newOption):
			state.selectedOption = newOption
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
	}
	
	enum Option: String, CaseIterable {
		case a
		case b
		case c
		
		var text: String {
			"Option \(rawValue.uppercased())"
		}
	}
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .optionSelection:
				let alert = UIAlertController(
					title: "Select option",
					message: nil,
					preferredStyle: .actionSheet
				)
				Option.allCases.forEach { option in
					alert.addAction(makeAction(for: option))
				}
				alert.addAction(UIAlertAction(
					title: "Cancel",
					style: .cancel,
					action: nil,
					store: store,
					toNavigationCasePath: \.modalNavigation
				))
				return alert
			}
		}
		
		func makeAction(for option: Option) -> UIAlertAction {
			UIAlertAction(
				title: option.text,
				style: .default,
				action: .optionSelected(option),
				store: store,
				toNavigationCasePath: \.modalNavigation
			)
		}
	}

	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		ExistingViewController(store: store)
	}
}

class ExistingViewController: UIViewController {
	var cancellables: Set<AnyCancellable> = []
	let store: StoreOf<ExistingViewShowcase>
	let navigationHandler: ModalNavigationHandler<ExistingViewShowcase.ViewProvider>
	
	init(store: Store<ExistingViewShowcase.State, ExistingViewShowcase.Action>) {
		self.store = store
		self.navigationHandler = ModalNavigationHandler(
			store: store.scope(
				state: \.modalNavigation,
				action: \.modalNavigation
			), viewProvider: ExistingViewShowcase.ViewProvider(store: store)
		)
		super.init(nibName: nil, bundle: nil)
		
		self.navigationHandler.setup(with: self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .systemBackground
		
		let selectButton = UIButton(type: .system)
		selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
		selectButton.setTitle("Select option", for: .normal)
		
		let optionLabel = UILabel()
		
		let stackView = UIStackView(arrangedSubviews: [
			selectButton,
			optionLabel
		])
		stackView.axis = .vertical
		stackView.alignment = .center
		stackView.spacing = 20
		stackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(stackView)
		
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
		])
		
		store.publisher.selectedOption
			.map { $0?.text ?? "No option selected" }
			.assign(to: \.text, on: optionLabel)
			.store(in: &cancellables)
	}
	
	@objc func selectButtonTapped() {
		store.send(.modalNavigation(.presentFullScreen(.optionSelection)))
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
