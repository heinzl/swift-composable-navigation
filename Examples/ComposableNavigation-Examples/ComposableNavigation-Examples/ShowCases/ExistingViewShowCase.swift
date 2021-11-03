import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture
import Combine

/// This example showcases how to reuse an already existing UIViewController subclass
/// by using a `NavigationHandler` in this case a `ModalNavigationHandler`
struct ExistingViewShowCase {
	
	// MARK: TCA
	
	enum Screen: String {
		case optionSelection
	}
	
	struct State: Equatable {
		var selectedOption: Option?
		var modalNavigation = ModalNavigation<Screen>.State()
	}
	
	enum Action: Equatable {
		case optionSelected(Option)
		case modalNavigation(ModalNavigation<Screen>.Action)
	}
	
	struct Environment {}
	
	private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .optionSelected(let newOption):
			state.selectedOption = newOption
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		ModalNavigation<Screen>.reducer()
			.pullback(
				state: \.modalNavigation,
				action: /Action.modalNavigation,
				environment: { _ in () }
			),
		privateReducer
	])
	
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
					toNavigationAction: Action.modalNavigation
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
				toNavigationAction: Action.modalNavigation
			)
		}
	}

	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		ExistingViewController(store: store)
	}
}

class ExistingViewController: UIViewController {
	let viewStore: ViewStore<ExistingViewShowCase.State, ExistingViewShowCase.Action>
	var cancellables: Set<AnyCancellable> = []
	let navigationHandler: ModalNavigationHandler<ExistingViewShowCase.ViewProvider>
	
	init(store: Store<ExistingViewShowCase.State, ExistingViewShowCase.Action>) {
		self.viewStore = ViewStore(store)
		self.navigationHandler = ModalNavigationHandler(
			store: store.scope(
				state: \.modalNavigation,
				action: ExistingViewShowCase.Action.modalNavigation
			), viewProvider: ExistingViewShowCase.ViewProvider(store: store)
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
		
		viewStore.publisher.selectedOption
			.map { $0?.text ?? "No option selected" }
			.assign(to: \.text, on: optionLabel)
			.store(in: &cancellables)
	}
	
	@objc func selectButtonTapped() {
		viewStore.send(.modalNavigation(.presentFullScreen(.optionSelection)))
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
