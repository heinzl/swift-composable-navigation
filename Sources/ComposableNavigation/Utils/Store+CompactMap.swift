import ComposableArchitecture

public extension Store where State: Equatable {
	func compactMap<NonOptionalState, Unwrapped>(
		_ transform: (Store<NonOptionalState, Action>) -> Unwrapped
	) -> Unwrapped? where State == NonOptionalState? {
		if var state = self.withState({ $0 }) {
			return transform(
				self.scope(
					state: {
						state = $0 ?? state
						return state
					},
					action: { $0 }
				)
			)
		} else {
			return nil
		}
	}
}
