import UIKit
import Combine
import ComposableArchitecture

open class ModalNavigationController<ViewProvider: ViewProviding>: UIViewController, UIAdaptivePresentationControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ModalItemNavigation = ModalNavigation<Item>
	
	internal let store: Store<ModalItemNavigation.State, ModalItemNavigation.Action>
	internal let viewStore: ViewStore<ModalItemNavigation.State, ModalItemNavigation.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItem: ViewControllerItem?
	
	private var cancellables = Set<AnyCancellable>()
	
	internal struct ViewControllerItem {
		let styledItem: ModalItemNavigation.StyledItem
		let viewController: UIViewController
	}
	
	public init(
		contentViewController: UIViewController,
		store: Store<ModalItemNavigation.State, ModalItemNavigation.Action>,
		viewProvider: ViewProvider
	) {
		self.store = store
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.currentViewControllerItem = nil
		
		super.init(nibName: nil, bundle: nil)
		
		addContent(contentViewController)
		
		viewStore.publisher.styledItem
			.sink { [weak self] in
				self?.updateModalViewController(newStyledItem: $0)
			}
			.store(in: &cancellables)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func addContent(_ viewController: UIViewController) {
		addChild(viewController)
		view.addSubview(viewController.view)
		viewController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
			view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor),
			view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor),
			view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
		])
		didMove(toParent: viewController)
	}
	
	private func updateModalViewController(newStyledItem: ModalItemNavigation.StyledItem?) {
		let oldStyledItem = currentViewControllerItem?.styledItem
		guard oldStyledItem != newStyledItem else {
			return
		}
		switch (oldStyledItem, newStyledItem) {
		case (.some, .none):
			// Dismiss old
			dimissModal()
		case (.none, .some(let newStyledItem)):
			// Present new
			presentModal(newStyledItem)
		case (.some(let oldStyledItem), .some(let newStyledItem)):
			// Dismiss old, present new
			let viewController: UIViewController
			if oldStyledItem.item == newStyledItem.item {
				// Same item use -> use same viewController
				// Only presentation style changed
				viewController = currentViewControllerItem!.viewController
				viewController.modalPresentationStyle = newStyledItem.style
			} else {
				viewController = makeViewController(for: newStyledItem)
			}
			dimissModal()
			presentModal(viewController, newStyledItem)
		default:
			break
		}
	}
	
	private func presentModal(_ newStyledItem: ModalItemNavigation.StyledItem) {
		let viewController = makeViewController(for: newStyledItem)
		presentModal(viewController, newStyledItem)
	}
	
	private func presentModal(
		_ viewController: UIViewController,
		_ styledItem: ModalItemNavigation.StyledItem
	) {
		present(viewController, animated: shouldAnimateModalChanges, completion: nil)
		
		currentViewControllerItem = ViewControllerItem(
			styledItem: styledItem,
			viewController: viewController
		)
	}
	
	private func makeViewController(for styledItem: ModalItemNavigation.StyledItem) -> UIViewController {
		let viewController = viewProvider.makeViewController(for: styledItem.item)
		viewController.modalPresentationStyle = styledItem.style
		viewController.presentationController?.delegate = self
		return viewController
	}
	
	private func dimissModal() {
		dismiss(animated: shouldAnimateModalChanges, completion: nil)
		currentViewControllerItem = nil
	}
	
	private var shouldAnimateModalChanges: Bool {
		UIView.areAnimationsEnabled
	}
	
	// MARK: UIAdaptivePresentationControllerDelegate
	
	open func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		currentViewControllerItem = nil
		viewStore.send(.dismiss)
	}
}

public extension Presentable {
	func withModal<ViewProvider: ViewProviding>(
		store: Store<ModalNavigation<ViewProvider.Item>.State, ModalNavigation<ViewProvider.Item>.Action>,
		viewProvider: ViewProvider
	) -> ModalNavigationController<ViewProvider> {
		ModalNavigationController(
			contentViewController: viewController,
			store: store,
			viewProvider: viewProvider
		)
	}
}
