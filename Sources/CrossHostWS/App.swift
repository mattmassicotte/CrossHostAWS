import AWSLambdaEvents
import AWSLambdaRuntime

@main
struct App {
	static func main() async throws {
		let runtime = LambdaRuntime { (event: APIGatewayWebSocketRequest, context: LambdaContext) -> APIGatewayWebSocketResponse in
			context.logger.info("received: \(event)")

			return APIGatewayWebSocketResponse(statusCode: .ok)
		}

		try await runtime.run()
	}
}
