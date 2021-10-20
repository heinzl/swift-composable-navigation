import UIKit
import ComposableArchitecture

public class ModalNavigationViewController<ViewProvider: ViewProviding>: UIViewController {
	internal let navigationHandler: ModalNavigationHandler<ViewProvider>
	
	public convenience init(
		contentViewController: UIViewController,
		store: Store<ModalNavigation<ViewProvider.Item>.State, ModalNavigation<ViewProvider.Item>.Action>,
		viewProvider: ViewProvider
	) {
		self.init(
			contentViewController: contentViewController,
			navigationHandler: ModalNavigationHandler(store: store, viewProvider: viewProvider)
		)
	}
	
	public init(
		contentViewController: UIViewController,
		navigationHandler: ModalNavigationHandler<ViewProvider>
	) {
		self.navigationHandler = navigationHandler
		super.init(nibName: nil, bundle: nil)
		
		addContent(contentViewController)
		self.navigationHandler.setup(with: self)
	}
	
	public required init?(coder: NSCoder) {
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
}

public extension Presentable {
	func withModal<ViewProvider: ViewProviding>(
		store: Store<ModalNavigation<ViewProvider.Item>.State, ModalNavigation<ViewProvider.Item>.Action>,
		viewProvider: ViewProvider
	) -> ModalNavigationViewController<ViewProvider> {
		ModalNavigationViewController(
			contentViewController: viewController,
			store: store,
			viewProvider: viewProvider
		)
	}
}
