import AWSLambdaEvents
import AWSLambdaRuntime
import HummingbirdLambda
import Logging

struct Configuration {
	let host: String
	let routePrefix: String
	let scheme: String = "https"

	init(host: String?, routePrefix: String?) {
		self.host = host ?? "localhost"
		self.routePrefix = routePrefix ?? ""
	}

	var urlPrefix: String {
		"\(scheme)://\(host)/\(routePrefix)"
	}
}

@main
struct AppLambda: APIGatewayV2LambdaFunction {
	typealias Context = BasicLambdaRequestContext<APIGatewayV2Request>

	let logger: Logger

	init(context: LambdaInitializationContext) {
		self.logger = context.logger
	}

	func buildResponder() -> some HTTPResponder<Context> {
		let env = Environment()
		let config = Configuration(
			host: env.get("DOMAIN"),
			routePrefix: env.get("ROUTE_PREFIX")
		)

		let router = Router(context: Context.self)

		router.add(middleware: ErrorMiddleware())
		router.add(middleware: LogRequestsMiddleware(.info))

		let group = router.group(RouterPath(config.routePrefix))

		group.get("/health") { _, _  in
			HTTPResponse.Status.ok
		}

		group.addRoutes(WebFingerController<Context>(configuration: config).endpoints, atPath: "/")
		group.addRoutes(NodeInfoController<Context>(configuration: config).endpoints, atPath: "/")
		group.addRoutes(HostMetaController<Context>(configuration: config).endpoints, atPath: "/")

		group.addRoutes(UserController<Context>(configuration: config).endpoints, atPath: "/")

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
