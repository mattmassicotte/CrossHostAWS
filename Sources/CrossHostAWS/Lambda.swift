import Foundation

import AWSLambdaEvents
import AWSLambdaRuntime
import HummingbirdLambda
import Logging

import CrossHost
import HummingbirdWebSocket

@main
struct App {
	typealias Context = BasicLambdaRequestContext<APIGatewayV2Request>

	static func main() async throws {
		let env = Environment()

		let url = URL(fileURLWithPath: "/opt/crosshost-p256.pem")
		let pemData = try String(contentsOf: url, encoding: .utf8)

		let config = ControllerConfiguration(
			host: env.get("DOMAIN"),
			routePrefix: env.get("ROUTE_PREFIX"),
			p256KeyPem: pemData
		)

		let app = App()
		let router = app.buildRouter(configuration: config)
		let lambda = APIGatewayV2LambdaFunction(router: router)

		try await lambda.runService()
	}

	func buildRouter(configuration: ControllerConfiguration) -> Router<Context> {
		let router = Router(context: Context.self)

		router.add(middleware: ErrorMiddleware())
		router.add(middleware: LogRequestsMiddleware(.info))
		router.add(middleware: CORSMiddleware())

		let group = router.group(RouterPath(configuration.routePrefix))

		router.get("/health") { _, _  in
			HTTPResponse.Status.ok
		}

		group.addRoutes(WebFingerController<Context>(configuration: configuration).endpoints, atPath: "/")
		group.addRoutes(NodeInfoController<Context>(configuration: configuration).endpoints, atPath: "/")
		group.addRoutes(HostMetaController<Context>(configuration: configuration).endpoints, atPath: "/")

		group.addRoutes(DIDWebController<Context>(configuration: configuration).endpoints, atPath: "/")
		group.addRoutes(ATProtoXRPCController<Context>(configuration: configuration).endpoints, atPath: "/")
		group.addRoutes(UserController<Context>(configuration: configuration).endpoints, atPath: "/")

		return router
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
			context.logger.error("failed: \(error)")
			
			throw error
		} catch {
			context.logger.error("failed: \(error)")

			throw HTTPError(.internalServerError, message: "Error: \(error)")
		}
	}
}

struct CORSMiddleware<Context: RequestContext>: RouterMiddleware {
	func handle(
		_ input: Request,
		context: Context,
		next: (Request, Context) async throws -> Response
	) async throws -> Response {
		var response = try await next(input, context)

		response.headers[.accessControlAllowOrigin] = "*"
		response.headers[.accessControlAllowMethods] = "*"

		return response
	}
}
