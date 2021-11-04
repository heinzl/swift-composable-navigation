import Foundation
import ComposableArchitecture
import OrderedCollections

/// `TabNavigation` models state and actions of a tab-based scheme for navigating multiple child views.
///
/// The active navigation item can be changed by setting a new item. Mutations to the items array
/// are reflected as well (e.g. changing the tab order).
public struct TabNavigation<Item: Equatable> {
	public struct State: Equatable {
		public var items: [Item]
		public var activeItem: Item
		
		public init(items: [Item], activeItem: Item) {
			self.items = items
			self.activeItem = activeItem
		}
	}
	
	public enum Action: Equatable {
		case setActiveItem(Item)
		case setActiveIndex(Int)
		case setItems([Item])
	}
	
	public static func reducer() -> Reducer<State, Action, Void> {
		Reducer { state, action, _ in
			switch action {
			case .setActiveItem(let newActiveItem):
				guard state.items.contains(newActiveItem) else {
					return .none
				}
				state.activeItem = newActiveItem
			case .setActiveIndex(let newIndex):
				guard state.items.indices.contains(newIndex) else {
					return .none
				}
				return .init(value: .setActiveItem(state.items[newIndex]))
			case .setItems(let newItems):
				state.items = newItems
				if !newItems.contains(state.activeItem) {
					return .init(value: .setActiveIndex(0))
				}
			}
			return .none
		}
	}
}
