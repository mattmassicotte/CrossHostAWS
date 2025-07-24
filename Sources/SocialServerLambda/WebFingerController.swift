import Hummingbird
import HTTPTypes

import WebFinger
import SocialServer

public struct AbstractWebFingerController<Responder: HTTPResponding>: Sendable {
	let configuration: Configuration

	init(configuration: Configuration) {
		self.configuration = configuration
	}

	func get(responder: Responder) async throws -> Responder.Response {
		guard
			let resource: String = responder.queryParameter(for: "resource"),
			let query = WebFingerResource.Query(resource: resource)
		else {
			return try await responder.statusResponse(.badRequest, headers: [:])
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

		return try await responder.jsonResponse(
			descriptor,
			headers: [.contentType: WebFingerResource.contentType]
		)
	}
}

enum HTTPResponseProvidingError: Error {
	case badHTTPField(String)
}

extension HTTPField {
	init(_ element: [String: String].Element) throws {
		guard let name = HTTPField.Name(element.key) else {
			throw HTTPResponseProvidingError.badHTTPField(element.key)
		}

		self.init(name: name, value: element.value)
	}
}

extension HTTPFields {
	init(_ dictionary: [String: String]) throws {
		let fields = try dictionary.map({ try HTTPField($0) })

		self.init(fields)
	}
}

public struct HummingBirdResponseProvider<Context: RequestContext>: HTTPResponding, Sendable {
	let context: Context
	let request: Request

	public func urlParameter(for key: String) -> String? {
		context.parameters.get(key)
	}

	public func queryParameters(for key: String) -> [String] {
		guard let param = request.uri.queryParameters[Substring(key)] else {
			return []
		}

		return [String(param)]
	}

	public func statusResponse(_ status: HTTPResponse.Status, headers: HTTPFields) async throws -> Response {
		Response(status: status, headers: headers)
	}

	public func jsonResponse<T: Encodable>(_ value: T, headers: HTTPFields) async throws -> Response {
		var response = try context.responseEncoder.encode(value, from: request, context: context)

		for header in headers {
			response.headers[header.name] = header.value
		}

		return response
	}
}

public struct WebFingerController<Context: RequestContext>: Sendable {
	let absract: AbstractWebFingerController<HummingBirdResponseProvider<Context>>
	let configuration: Configuration

	init(configuration: Configuration) {
		self.configuration = configuration
		self.absract = AbstractWebFingerController(configuration: configuration)
	}

	var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/.well-known/webfinger", use: get)
	}

	func get(request: Request, context: Context) async throws -> Response {
		let responder = HummingBirdResponseProvider(context: context, request: request)

		return try await absract.get(responder: responder)
	}
}
