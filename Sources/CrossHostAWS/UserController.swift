import Hummingbird

import JSONLD
import AsyncHTTPClient

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct APPublicKey: Codable, Identifiable {
	let id: String
	let owner: String?
	let controller: String?
	let publicKeyPem: String

	public init(id: String, controller: String, publicKeyPem: String) {
		self.id = id
		self.owner = controller
		self.controller = controller
		self.publicKeyPem = publicKeyPem
	}
}

struct APActor: JSONLDDocument, Identifiable {
	enum CodingKeys: String, CodingKey {
		case context = "@context"
		case id
		case type
		case preferredUsername
		case inbox
		case outbox
		case publicKey
	}

	let context: ContextDefinition
	let id: String
	let type: String
	let preferredUsername: String
	let inbox: String
	let outbox: String
	let publicKey: APPublicKey

	public init(context: ContextDefinition, id: String, type: String, preferredUsername: String, inbox: String, outbox: String, publicKey: APPublicKey) {
		self.context = context
		self.id = id
		self.type = type
		self.preferredUsername = preferredUsername
		self.inbox = inbox
		self.outbox = outbox
		self.publicKey = publicKey
	}
}

struct APOutbox: JSONLDDocument, Identifiable {
	enum CodingKeys: String, CodingKey {
		case context = "@context"
		case id
		case type
		case totalItems
		case first
		case last
	}

	let context: ContextDefinition
	let id: String
	let type: String
	let totalItems: Int
	let first: String
	let last: String

	public init(context: ContextDefinition, id: String, type: String, totalItems: Int, first: String, last: String) {
		self.context = context
		self.id = id
		self.type = type
		self.totalItems = totalItems
		self.first = first
		self.last = last
	}
}

struct APOutboxContent: JSONLDDocument, Identifiable {
	struct Item: Codable {
		struct ItemObject: Codable {
			let id: String
			let type: String
			let content: String

			init(id: String, type: String, content: String) {
				self.id = id
				self.type = type
				self.content = content
			}
		}

		let id: String
		let type: String
		let actor: String
		let published: String
		let to: [String]
		let cc: [String]
		let object: ItemObject

		init(id: String, type: String, actor: String, published: String, to: [String], cc: [String], object: ItemObject) {
			self.id = id
			self.type = type
			self.actor = actor
			self.published = published
			self.to = to
			self.cc = cc
			self.object = object
		}
	}

	enum CodingKeys: String, CodingKey {
		case context = "@context"
		case id
		case type
		case next
		case prev
		case partOf
		case orderedItems
	}

	let context: ContextDefinition
	let id: String
	let type: String
	let next: String?
	let prev: String?
	let partOf: String
	let orderedItems: [Item]

	init(context: ContextDefinition, id: String, type: String, next: String?, prev: String?, partOf: String, orderedItems: [Item]) {
		self.context = context
		self.id = id
		self.type = type
		self.next = next
		self.prev = prev
		self.partOf = partOf
		self.orderedItems = orderedItems
	}
}

struct APFollowRequest: JSONLDDocument, Identifiable {
	enum CodingKeys: String, CodingKey {
		case context = "@context"
		case id
		case type
		case actor
		case object
	}

	let context: ContextDefinition
	let id: String
	let type: String
	let actor: String
	let object: String
}

extension AsyncSequence {
	func collect() async throws -> [Element] {
		try await reduce(into: [Element]()) { $0.append($1) }
	}
}

struct UserController<Context: RequestContext>: Sendable {
	let configuration: Configuration

	init(configuration: Configuration) {
		self.configuration = configuration
	}

	var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/users/:id", use: get)
			.post("/users/:id/inbox", use: inbox)
			.get("/users/:id/outbox", use: outbox)
			.get("/users/:id/outbox/contents", use: outboxContents)
	}

	func get(request: Request, context: Context) async throws -> Response {
		let id = try context.parameters.require("id")
		let userURLPrefix = "\(configuration.urlPrefix)/users/\(id)"
		let examplePublicKey = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmjEJrnVOVwUz9oBMdJL7
EwdvoUcbbHvkbPKLq/cxwdnNoPfxMxCB0c+Wkzk772J/+mxEfpDDvoIAdbO+fknE
LQYH+rGn9hyRNtdzWLykc25ebPIjMC00qO8KwL7vZSIRJPRK/+GmQatKtUyXehCA
U0wl3hLOrnbhOdLx+bPUa//Y2UTpHV0Xs1K575COq5Xf48pKiqjpEcMqwWWsZ6Ya
b68hwMV1oEzwtfuNKLG1XETMRbsIqpxTsbBD0D8Rofdu/mjJggc9W3YuBG3O9Q/1
R4lvv7YibVqnjGOljedTjkwNhrr4Zmczp9keDWkBf81ejrRILC+/x3hZo41Navjk
8QIDAQAB
-----END PUBLIC KEY-----   
"""
		let apActor = APActor(
			context: [
				"https://www.w3.org/ns/activitystreams",
				"https://w3id.org/security/v1",
			],
			id: userURLPrefix,
			type: "Person",
			preferredUsername: id,
			inbox: "\(userURLPrefix)/inbox",
			outbox: "\(userURLPrefix)/outbox",
			publicKey: APPublicKey(
				id: "\(userURLPrefix)#main-key",
				controller: userURLPrefix,
				publicKeyPem: examplePublicKey
			)
		)

		var response = try context.responseEncoder.encode(apActor, from: request, context: context)

		response.headers[.contentType] = "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""

		return response
	}

	func inbox(request: Request, context: Context) async throws -> Response {
		context.logger.info("inbox: \(request)")

		let _ = try context.parameters.require("id")

		if let followRequest = try? await request.decode(as: APFollowRequest.self, context: context) {
			context.logger.info("follow: \(followRequest.actor)")

			var request = HTTPClientRequest(url: followRequest.actor)

			request.headers.replaceOrAdd(
				name: "Accept",
				value: "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""
			)

			let response = try await HTTPClient.shared.execute(request, timeout: .seconds(4))
			guard response.status.code >= 200 && response.status.code < 300 else {
				context.logger.info("actor unavailable")
				return Response(status: .unprocessableContent)
			}

			let body = try await response.body.collect(upTo: 1024 * 1024)
			let follower = try JSONDecoder().decode(APActor.self, from: Data(buffer: body))

			context.logger.info("follower inbox: \(follower.inbox)")
		}

		return Response(status: .accepted)
	}

	func outbox(request: Request, context: Context) async throws -> Response {
		context.logger.info("outbox: \(request)")

		let id = try context.parameters.require("id")
		let userURLPrefix = "\(configuration.urlPrefix)/users/\(id)"

		let outbox = APOutbox(
			context: "https://www.w3.org/ns/activitystreams",
			id: "\(userURLPrefix)/outbox",
			type: "OrderedCollection",
			totalItems: 2,
			first: "\(userURLPrefix)/outbox/contents",
			last: "\(userURLPrefix)/outbox/contents?from=0"
		)

		var response = try context.responseEncoder.encode(outbox, from: request, context: context)

		response.headers[.contentType] = "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""

		return response
	}

	func outboxContents(request: Request, context: Context) async throws -> Response {
		context.logger.info("outbox contents: \(request)")

		let id = try context.parameters.require("id")
		let userURLPrefix = "\(configuration.urlPrefix)/users/\(id)"

		let content = APOutboxContent(
			context: "https://www.w3.org/ns/activitystreams",
			id: "\(userURLPrefix)/outbox/contents",
			type: "OrderedCollectionPage",
			next: nil,
			prev: nil,
			partOf: "\(userURLPrefix)/outbox",
			orderedItems: [
				APOutboxContent.Item(
					id: "\(configuration.urlPrefix)/posts/1",
					type: "Create",
					actor: userURLPrefix,
					published: "2025-07-23T00:01:00Z",
					to: ["https://www.w3.org/ns/activitystreams#Public"],
					cc: ["\(userURLPrefix)/followers"],
					object: APOutboxContent.Item.ItemObject(
						id: "\(configuration.urlPrefix)/posts/2",
						type: "Note",
						content: "\\u003cp\\u003eMuch better, thank you Aziz\\u003c/p\\u003e"
					)
				),
				APOutboxContent.Item(
					id: "\(configuration.urlPrefix)/posts/1",
					type: "Create",
					actor: userURLPrefix,
					published: "2025-07-23T00:00:00Z",
					to: ["https://www.w3.org/ns/activitystreams#Public"],
					cc: ["\(userURLPrefix)/followers"],
					object: APOutboxContent.Item.ItemObject(
						id: "\(configuration.urlPrefix)/posts/1",
						type: "Note",
						content: "\\u003cp\\u003eAZIZ, LIGHT!\\u003c/p\\u003e"
					)
				),
			]
		)

		var response = try context.responseEncoder.encode(content, from: request, context: context)

		response.headers[.contentType] = "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""

		return response
	}
}
