import UIKit
import ComposableArchitecture

/// A convenience UINavigationController implementation containing a `StackNavigationHandler`.
public class StackNavigationViewController<ViewProvider: ViewProviding>: UINavigationController {
	internal let navigationHandler: StackNavigationHandler<ViewProvider>
	
	public convenience init(
		store: StoreOf<StackNavigation<ViewProvider.Item>>,
		viewProvider: ViewProvider
	) {
		self.init(navigationHandler: StackNavigationHandler(store: store, viewProvider: viewProvider))
	}
	
	public init(navigationHandler: StackNavigationHandler<ViewProvider>) {
		self.navigationHandler = navigationHandler
		super.init(nibName: nil, bundle: nil)
		self.navigationHandler.setup(with: self)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
