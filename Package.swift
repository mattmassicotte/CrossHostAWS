// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "SocialServerLambda",
	platforms: [.macOS(.v14)],
	products: [
		.executable(name: "SocialServerLambda", targets: ["SocialServerLambda"])
	],
	dependencies: [
		.package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
		.package(url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.0.0-rc.2"),
		.package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha.3"),
		.package(path: "/Users/matt/Developer/SocialServer"),

	],
	targets: [
		.executableTarget(
			name: "SocialServerLambda",
			dependencies: [
				.product(name: "Hummingbird", package: "hummingbird"),
				.product(name: "HummingbirdLambda", package: "hummingbird-lambda"),
				"SocialServer",
			]
		),
	]
)
