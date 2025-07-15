import Hummingbird

import WebFinger

public struct WebFingerController<Context: RequestContext>: Sendable {
	let configuration: Configuration

	init(configuration: Configuration) {
		self.configuration = configuration
	}

	var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/.well-known/webfinger", use: get)
	}

	func get(request: Request, context: some RequestContext) async throws -> Response {
		guard
			let resource = request.uri.queryParameters["resource"],
			let query = WebFingerResource.Query(resource: String(resource))
		else {
			return Response(status: .badRequest)
		}

		let descriptor = WebFingerResource.Descriptor(
			subject: query.resource,
			aliases: nil,
			links: [
				WebFingerResource.Descriptor.Link(
					rel: "self",
					type: "application/activity+json",
					href: "\(configuration.urlPrefix)/users/\(query.user)"
				)
			]
		)

		var response = try context.responseEncoder.encode(descriptor, from: request, context: context)

		response.headers[.contentType] = WebFingerResource.contentType

		return response
	}
}
