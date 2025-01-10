// swift-tools-version:5.9

import PackageDescription

let package = Package(
	name: "ComposableNavigation",
	platforms: [.iOS(.v13)],
	products: [
		.library(
			name: "ComposableNavigation",
			targets: ["ComposableNavigation"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0"),
		.package(url: "https://github.com/apple/swift-collections", from: "1.0.4"),
	],
	targets: [
		.target(
			name: "ComposableNavigation",
			dependencies: [
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "OrderedCollections", package: "swift-collections"),
			]
		),
		.testTarget(
			name: "ComposableNavigationTests",
			dependencies: ["ComposableNavigation"]
		),
	]
)
