import ComposableArchitecture
import OrderedCollections

/// `StackNavigation` models state and actions of a stack-based scheme for navigating hierarchical content.
/// Views can be pushed on the stack or popped from the stack. Even mutations to the whole stack can be performed.
public struct StackNavigation<Item: Equatable> {
	public struct State: Equatable {
		public var items: [Item]
		
		public init(items: [Item]) {
			self.items = items
		}
		
		public var topItem: Item? {
			items.last
		}
	}
	
	public enum Action: Equatable {
		case pushItem(Item)
		case pushItems([Item])
		case popItem
		case popItems(count: Int)
		case popToRoot
		case setItems([Item])
	}
	
	public static func reducer() -> Reducer<State, Action, Void> {
		Reducer { state, action, _ in
			switch action {
			case .pushItem(let item):
				return Effect(value: .pushItems([item]))
			case .pushItems(let items):
				state.items.append(contentsOf: items)
			case .popItem:
				return Effect(value: .popItems(count: 1))
			case .popItems(let count):
				guard state.items.count >= count else {
					return .none
				}
				state.items.removeLast(count)
			case .popToRoot:
				return Effect(value: .popItems(count: state.items.count - 1))
			case .setItems(let items):
				state.items = items
			}
			return .none
		}
	}
}
