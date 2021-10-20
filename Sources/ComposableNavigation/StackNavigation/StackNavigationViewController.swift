import UIKit
import ComposableArchitecture

public class StackNavigationViewController<ViewProvider: ViewProviding>: UINavigationController {
	internal let navigationHandler: StackNavigationHandler<ViewProvider>
	
	public convenience init(
		store: Store<StackNavigation<ViewProvider.Item>.State, StackNavigation<ViewProvider.Item>.Action>,
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
