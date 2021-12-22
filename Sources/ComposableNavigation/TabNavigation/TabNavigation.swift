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
		public var areAnimationsEnabled: Bool
		
		public init(
			items: [Item],
			activeItem: Item,
			areAnimationsEnabled: Bool = true
		) {
			self.items = items
			self.activeItem = activeItem
			self.areAnimationsEnabled = areAnimationsEnabled
		}
	}
	
	public enum Action: Equatable {
		case setActiveItem(Item)
		case setActiveIndex(Int)
		case setItems([Item], animated: Bool = true)
	}
	
	public static func reducer() -> Reducer<State, Action, Void> {
		Reducer { state, action, _ in
			switch action {
			case .setActiveItem(let newActiveItem):
				setActiveItem(newActiveItem, on: &state)
			case .setActiveIndex(let newIndex):
				setActiveIndex(newIndex, on: &state)
			case let .setItems(newItems, animated):
				state.items = newItems
				state.areAnimationsEnabled = animated
				if !newItems.contains(state.activeItem) {
					setActiveIndex(0, on: &state)
				}
			}
			return .none
		}
	}
	
	private static func setActiveIndex(_ index: Int, on state: inout State) {
		guard state.items.indices.contains(index) else {
			return
		}
		state.activeItem = state.items[index]
	}
	
	private static func setActiveItem(_ item: Item, on state: inout State) {
		guard state.items.contains(item) else {
			return
		}
		state.activeItem = item
	}
}
