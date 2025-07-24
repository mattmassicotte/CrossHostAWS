import Hummingbird

struct HostMetaController<Context: RequestContext>: Sendable {
	let configuration: Configuration

	init(configuration: Configuration) {
		self.configuration = configuration
	}

	var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/.well-known/host-meta", use: get)
	}

	func get(request: Request, context: some RequestContext) async throws -> Response {
		let content = """
<?xml version="1.0" encoding="UTF-8"?>
<xrd xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
  <link rel="lrdd" template="\(configuration.urlPrefix)/.well-known/webfinger?resource={uri}" />
</xrd>   
"""

		let buffer = ByteBuffer(string: content)
		return Response(
			status: .ok,
			headers: [.contentType: "application/xrd+xml"],
			body: ResponseBody(byteBuffer: buffer)
		)
	}
}
