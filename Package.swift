// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "CrossHostAWS",
	platforms: [.macOS(.v15)],
	products: [
		.executable(name: "CrossHostAWS", targets: ["CrossHostAWS"]),
		.executable(name: "CrossHostWS", targets: ["CrossHostWS"])
	],
	dependencies: [
		.package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
		.package(url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.0.1"),
		.package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.6.0"),
		.package(url: "https://github.com/mattmassicotte/CrossHost", branch: "main"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.6.0"),
		.package(url: "https://github.com/awslabs/swift-aws-lambda-events", from: "1.2.4"),
		.package(url: "https://github.com/awslabs/swift-aws-lambda-runtime", from: "2.3.1"),
		.package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
		.package(url: "https://github.com/mattmassicotte/JSONLD", branch: "main"),
		.package(url: "https://github.com/mattmassicotte/HTTPSignature", branch: "main"),
		.package(url: "https://github.com/mattmassicotte/ATAT", branch: "main"),

		.package(url: "https://github.com/swift-libp2p/swift-cid", branch: "main"),
	],
	targets: [
		.executableTarget(
			name: "CrossHostAWS",
			dependencies: [
				.product(name: "Hummingbird", package: "hummingbird"),
				.product(name: "HummingbirdLambda", package: "hummingbird-lambda"),
				.product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
				"CrossHost",
				"JSONLD",
				"HTTPSignature",
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "_CryptoExtras", package: "swift-crypto"),
				"ATAT",
				.product(name: "CID", package: "swift-cid"),
			],
		),
		.executableTarget(
			name: "CrossHostWS",
			dependencies: [
				.product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
				.product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
				"CrossHost",
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
			],
		),
		.testTarget(
			name: "CrossHostAWSTests",
			dependencies: [
				"CrossHostAWS",
			]
		)
	]
)
