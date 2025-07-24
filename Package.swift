// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "CrossHostAWS",
	platforms: [.macOS(.v14)],
	products: [
		.executable(name: "CrossHostAWS", targets: ["CrossHostAWS"])
	],
	dependencies: [
		.package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
		.package(url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.0.0-rc.2"),
		.package(url: "https://github.com/mattmassicotte/CrossHost", branch: "main"),
		.package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha.3"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.6.0"),

		.package(url: "https://github.com/mattmassicotte/JSONLD", branch: "main"),
	],
	targets: [
		.executableTarget(
			name: "CrossHostAWS",
			dependencies: [
				.product(name: "Hummingbird", package: "hummingbird"),
				.product(name: "HummingbirdLambda", package: "hummingbird-lambda"),
				"CrossHost",
				"JSONLD",
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
			]
		),
	]
)
