import ComposableArchitecture
import OrderedCollections

/// `StackNavigation` models state and actions of a stack-based scheme for navigating hierarchical content.
/// Views can be pushed on the stack or popped from the stack. Even mutations to the whole stack can be performed.
@Reducer
public struct StackNavigation<Item: Equatable> {
	public init() {}
	
	@ObservableState
	public struct State: Equatable {
		public var items: [Item]
		public var areAnimationsEnabled: Bool
		
		public init(
			items: [Item],
			areAnimationsEnabled: Bool = true
		) {
			self.items = items
			self.areAnimationsEnabled = areAnimationsEnabled
		}
		
		public var topItem: Item? {
			items.last
		}
	}
	
	@CasePathable
	public enum Action {
		case pushItem(Item, animated: Bool = true)
		case pushItems([Item], animated: Bool = true)
		case popItem(animated: Bool = true)
		case popItems(count: Int, animated: Bool = true)
		case popToRoot(animated: Bool = true)
		case setItems([Item], animated: Bool = true)
	}
	
	public func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case let .pushItem(item, animated):
			setItems(state.items + [item], on: &state, animated: animated)
		case let .pushItems(items, animated):
			setItems(state.items + items, on: &state, animated: animated)
		case let .popItem(animated):
			popItems(count: 1, on: &state, animated: animated)
		case let .popItems(count, animated):
			popItems(count: count, on: &state, animated: animated)
		case let .popToRoot(animated):
			popItems(count: state.items.count - 1, on: &state, animated: animated)
		case let .setItems(items, animated):
			setItems(items, on: &state, animated: animated)
		}
		return .none
	}
	
	private func setItems(_ items: [Item], on state: inout State, animated: Bool) {
		state.items = items
		state.areAnimationsEnabled = animated
	}
	
	private func popItems(count: Int, on state: inout State, animated: Bool) {
		guard state.items.count >= count, count >= 0 else {
			return
		}
		state.items.removeLast(count)
		state.areAnimationsEnabled = animated
	}
}
