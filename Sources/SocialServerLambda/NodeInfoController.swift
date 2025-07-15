import Hummingbird

import NodeInfo

public struct NodeInfoController<Context: RequestContext>: Sendable {
	let host: String
	let routingPrefix: String

	public init(host: String, routingPrefix: String) {
		self.host = host
		self.routingPrefix = routingPrefix
	}

	public var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/.well-known/nodeinfo", use: getProtocolDocument)
			.get("/nodeinfo/2.1", use: getNodeInfo_2_1)
	}

	func getProtocolDocument(request: Request, context: some RequestContext) async throws -> Response {
		let document = NodeInfoProtocol.Document(
			links: [
				NodeInfoProtocol.Link(
					rel: NodeInfoVersion.version_2_1.uri,
					href: "https://\(host)\(routingPrefix)/nodeinfo/2.1"
				),
				NodeInfoProtocol.Link(
					rel: NodeInfoVersion.version_2_0.uri,
					href: "https://\(host)\(routingPrefix)/nodeinfo/2.0"

				)
			]
		)

		var response = try context.responseEncoder.encode(document, from: request, context: context)

		response.headers[.contentType] = "application/json; charset=utf-8"

		return response
	}

	func getNodeInfo_2_1(request: Request, context: some RequestContext) async throws -> Response {
		let document = NodeInfo_2_1.Document(
			software: NodeInfo_2_1.Software(
				name: "SocialServer",
				version: "0.1",
				repository: "https://github.com/mattmassicotte/SocialServerLambda",
				homepage: "https://github.com/mattmassicotte/SocialServer"
			),
			protocols: [.activitypub],
			services: NodeInfo_2_1.Services(inbound: [], outbound: []),
			openRegistrations: false,
			usage: NodeInfo_2_1.Usage(
				users: NodeInfo_2_1.Usage.Users(
					total: 1,
					activeHalfyear: 1,
					activeMonth: 1
				),
				localPosts: 0,
				localComments: 0
			)
		)

		var response = try context.responseEncoder.encode(document, from: request, context: context)

		response.headers[.contentType] = "application/json; charset=utf-8; profile=\"\(NodeInfoVersion.version_2_1.uriProfile)\""

		return response
	}
}
