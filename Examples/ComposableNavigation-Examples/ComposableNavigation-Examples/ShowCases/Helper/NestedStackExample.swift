import Foundation

extension NestedStack.State {
	static let example: Self = .init(modalLevel: 1, nestedModals: [
		.init(modalLevel: 1, stackLevel: 1),
		.init(modalLevel: 1, stackLevel: 2, nestedStack: .init(
			modalLevel: 2,
			nestedModals: [
				.init(modalLevel: 2, stackLevel: 1),
				.init(modalLevel: 2, stackLevel: 2, nestedStack: .init(
					modalLevel: 3,
					nestedModals: [
						.init(modalLevel: 3, stackLevel: 1),
						.init(modalLevel: 3, stackLevel: 2, nestedStack: .init(
							modalLevel: 4,
							nestedModals: [
								.init(modalLevel: 4, stackLevel: 1),
								.init(modalLevel: 4, stackLevel: 2, nestedStack: .init(
									modalLevel: 5,
									nestedModals: [
										.init(modalLevel: 5, stackLevel: 1),
										.init(modalLevel: 5, stackLevel: 2)
									]
								))
							]
						))
					]
				))
			]
		))
	])
}
