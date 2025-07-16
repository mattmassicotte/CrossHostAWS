import Hummingbird

struct UserController<Context: RequestContext>: Sendable {
	let configuration: Configuration

	init(configuration: Configuration) {
		self.configuration = configuration
	}

	var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/users/:id", use: get)
	}

	func get(request: Request, context: some RequestContext) async throws -> Response {
		let id = try context.parameters.require("id")

		let content = "{\"user\":\"\(id)\"}"

		let buffer = ByteBuffer(string: content)
		return Response(
			status: .ok,
			headers: [.contentType: "application/json"],
			body: ResponseBody(byteBuffer: buffer)
		)
	}
}
