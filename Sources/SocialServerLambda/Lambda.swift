import AWSLambdaEvents
import AWSLambdaRuntime
import HummingbirdLambda
import Logging

@main
struct AppLambda: APIGatewayV2LambdaFunction {
	typealias Context = BasicLambdaRequestContext<APIGatewayV2Request>

	let logger: Logger

	init(context: LambdaInitializationContext) {
		self.logger = context.logger
	}

	func buildResponder() -> some HTTPResponder<Context> {
		let env = Environment()
		let value = env.get("LOG_LEVEL") ?? "empty"
		self.logger.info("LOG_LEVEL: \(value)")

		let router = Router(context: Context.self)

		router.add(middleware: ErrorMiddleware())

		let prefix = "/" + (env.get("ROUTE_PREFIX") ?? "")

		let group = router.group(RouterPath(prefix))

		group.add(middleware: LogRequestsMiddleware(.info))

		group.get("/health") { _, _  in
			HTTPResponse.Status.ok
		}

		let host = env.get("DOMAIN") ?? "localhost"

		group.addRoutes(WebFingerController<Context>(host: host, routingPrefix: prefix).endpoints, atPath: "/")
		group.addRoutes(NodeInfoController<Context>(host: host, routingPrefix: prefix).endpoints, atPath: "/")

		return router.buildResponder()
	}

	func shutdown() async throws {
		self.logger.info("Shutdown")
	}
}

struct ErrorMiddleware<Context: RequestContext>: RouterMiddleware {
	func handle(
		_ input: Request,
		context: Context,
		next: (Request, Context) async throws -> Response
	) async throws -> Response {
		do {
			return try await next(input, context)
		} catch let error as HTTPError {
			throw error
		} catch {
			throw HTTPError(.internalServerError, message: "Error: \(error)")
		}
	}
}
