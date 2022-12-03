[![CI](https://github.com/heinzl/swift-composable-navigation/actions/workflows/main.yml/badge.svg)](https://github.com/heinzl/swift-composable-navigation/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/heinzl/swift-composable-navigation/branch/main/graph/badge.svg?token=PI59Z580YX)](https://codecov.io/gh/heinzl/swift-composable-navigation)

# Composable Navigation

The Composable Navigation is a Swift Package that builds on top of [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA, for short). It models UI navigation patterns using TCA. The corresponding navigation views are implemented in UIKit. 

The concept is inspired by the coordinator pattern as it allows a clean separation between individual screens and the logic that ties those screens together. In a TCA world, a coordinator is represented by a state composed of its child views' sub-states and the navigation state. A reducer would then be able to manage the navigation state similar as a coordinator would do by observing actions from child views and presenting/dismissing other screens.

## Features

### Modal navigation

`ModalNavigation` models state and actions of a commonly used modal view presentation.
Views can be presented with a certain style and dismissed. The `ModalNavigationHandler` listens to state changes and presents the provided views accordingly. Any state changes are reflected by the handler using UIKit.

Setting the current navigation item to a different screen will result in dismissing the old screen and presenting the new screen. Even changes to only the presentation style are reflected accordingly.

It also supports automatic state updates for pull-to-dismiss for views presented as a sheet.

This example shows how a modal-navigation could be implemented using an enum:
```swift
struct Onboarding {
    enum Screen {
        case login
        case register
    }

    struct State: Equatable {
        var modalNavigation = ModalNavigation<Screen>.State()
        ...
    }

    enum Action: Equatable {
        case modalNavigation(ModalNavigation<Screen>.Action)
        ...
    }

    private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .loginButtonPressed:
            return .task { .modalNavigation(.presentFullScreen(.login)) }
        case .anotherAction:
            return .task { .modalNavigation(.dismiss) }
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
}
```

### Stack navigation

`StackNavigation` models state and actions of a stack-based scheme for navigating hierarchical content.
Views can be pushed on the stack or popped from the stack. Even mutations to the whole stack can be performed. The `StackNavigationHandler` listens to state changes and updates the view stack accordingly using UIKit.

It also supports automatic state updates for popping items via the leading-edge swipe gesture or the long press back-button menu.

This example shows how a series of text inputs could be implemented:
```swift
struct Register {
    enum Screen {
        case email
        case firstName
        case lastName
    }

    struct State: Equatable {
        var stackNavigation = StackNavigation<Screen>.State(items: [.email])
        ...
    }

    enum Action: Equatable {
        case stackNavigation(StackNavigation<Screen>.Action)
        ...
    }

    private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .emailEntered:
            return .task { .stackNavigation(.pushItem(.firstName)) }
        case .firstNameEntered:
            return .task { .stackNavigation(.pushItem(.lastName)) }
        ...
        }
        return .none
    }

    static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
        StackNavigation<Screen>.reducer()
            .pullback(
                state: \.stackNavigation,
                action: /Action.stackNavigation,
                environment: { _ in () }
            ),
        privateReducer
    ])
}
```

### Tab navigation

`TabNavigation` models state and actions of a tab-based scheme for navigating multiple child views.
The active navigation item can be changed by setting a new item. Even mutations to items array can be performed (e.g. changing the tab order). The `TabNavigationHandler` listens to state changes and updates the selected view or tab order accordingly.

Example:
```swift
struct Root {
    enum Screen: CaseIterable {
        case home
        case list
        case settings
    }

    struct State: Equatable {
        var tabNavigation = TabNavigation<Screen>.State(
            items: Screen.allCases,
            activeItem: .home
        )
        ...
    }

    enum Action: Equatable {
        case tabNavigation(TabNavigation<Screen>.Action)
        ...
    }

    private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
        switch action {
        case .goToSettings:
            return .task { .tabNavigation(.setActiveItem(.settings)) }
        ...
        }
        return .none
    }

    static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
        TabNavigation<Screen>.reducer()
            .pullback(
                state: \.tabNavigation,
                action: /Action.tabNavigation,
                environment: { _ in () }
            ),
        privateReducer
    ])
}
```

### ViewProviding

The `ViewProvider` creates a view according to the given navigation item. It implements `ViewProviding` which requires the type to create a `Presentable` (e.g. a SwiftUI View or a UIViewController) for a given navigation item.

Navigation handler (like `StackNavigationHandler`) expect a `ViewProvider`. It is used to create new views. The navigation handler will reuse the already created view for `.b` if the stack of navigation items changes like this: `[.a, .b, .c]` -> `[.x, .y, .b,]`

```swift
struct ViewProvider: ViewProviding {
    let store: Store<State, Action>
    
    func makePresentable(for navigationItem: Screen) -> Presentable {
        switch navigationItem {
        case .a:
            return ViewA(store: store.scope( ... ))
        case .b:
            return ViewB(store: store.scope( ... ))
        }
    }
}
```

## Usage

A navigation container view can be integrated like any other `UIViewController` in your app.

This is an example of a `TabNavigationViewController` in a `SceneDelegate`:
```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

    lazy var store: Store<App.State, App.Action> = ...

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}
		
		let controller = TabNavigationViewController(
			store: store.scope(
				state: \.tabNavigation,
				action: App.Action.tabNavigation
			),
			viewProvider: App.ViewProvider(store: store)
		)

		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = controller
		self.window = window
		window.makeKeyAndVisible()
	}

    ...
}
```

You can use the corresponding "handlers" instead e.g. (`ModalNavigationHandler`) if you already have a custom view controller implementation.
Make sure to call `navigationHandler.setup(with: viewController)` similar to this:

```swift
class ExistingViewController: UIViewController {
	let viewStore: ViewStore<ExistingViewShowcase.State, ExistingViewShowcase.Action>
	var cancellables: Set<AnyCancellable> = []
	let navigationHandler: ModalNavigationHandler<ExistingViewShowcase.ViewProvider>
	
	init(store: Store<ExistingViewShowcase.State, ExistingViewShowcase.Action>) {
		self.viewStore = ViewStore(store)
		self.navigationHandler = ModalNavigationHandler(
			store: store.scope(
				state: \.modalNavigation,
				action: ExistingViewShowcase.Action.modalNavigation
			), viewProvider: ExistingViewShowcase.ViewProvider(store: store)
		)
		super.init(nibName: nil, bundle: nil)
		
		self.navigationHandler.setup(with: self)
	}
	
	...
}
```


#### Existing UINavigationController
`StackNavigationHandler` can be initialized with the `ignorePreviousViewControllers: Bool` parameter. When this parameter is set to `true` the `StackNavigationHandler` will ignore the view controllers that are already on the stack. This is particularly helpful when Composable Navigation is used on top of already existing code. 

## Showcases

You can find multiple showcases in the [Examples project](Examples/ComposableNavigation-Examples/ComposableNavigation-Examples/).

The example app hosts multiple showcases (and UI tests), to run one of the showcase you need to changes the variable `showcase` in `SceneDelegate.swift`.

```swift
...
// 👉 Choose showcase 👈
let showcase: Showcase = .advanced
...
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
