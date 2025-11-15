import AWSLambdaEvents
import AWSLambdaRuntime

public struct MyAPIGatewayWebSocketRequest: Codable {
	/// `Context` contains information to identify the AWS account and resources invoking the Lambda function.
	public struct Context: Codable {
		public struct Identity: Codable {
			public let sourceIp: String
		}

		public let routeKey: String
		public let eventType: String
		public let extendedRequestId: String
		/// The request time in format: 23/Apr/2020:11:08:18 +0000
		public let requestTime: String
		public let messageDirection: String
		public let stage: String
		public let connectedAt: UInt64
		public let requestTimeEpoch: UInt64
		public let identity: Identity
		public let requestId: String
		public let domainName: String
		public let connectionId: String
		public let apiId: String
	}

	public let headers: HTTPHeaders?
	public let queryStringParameters: [String: String]?
	public let multiValueHeaders: HTTPMultiValueHeaders?
	public let context: Context
	public let body: String?
	public let isBase64Encoded: Bool?

	enum CodingKeys: String, CodingKey {
		case headers
		case queryStringParameters
		case multiValueHeaders
		case context = "requestContext"
		case body
		case isBase64Encoded
	}
}

@main
struct App {
	static func main() async throws {
		let runtime = LambdaRuntime { (event: MyAPIGatewayWebSocketRequest, context: LambdaContext) -> APIGatewayWebSocketResponse in
			context.logger.info("\(event.context.routeKey) \(event.context.requestId) \(event.queryStringParameters ?? [:])")

			return APIGatewayWebSocketResponse(statusCode: .ok)
		}

		try await runtime.run()
	}
}
