import Hummingbird

import AsyncHTTPClient

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import HTTPSignature
import Crypto
import _CryptoExtras
import CrossHost
import ActivityPub

struct UserController<Context: RequestContext>: Sendable {
	let configuration: ControllerConfiguration

	init(configuration: ControllerConfiguration) {
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

		let id = try context.parameters.require("id")
		if id != "test" {
			return Response(status: .notFound)
		}

		let userURLPrefix = "\(configuration.urlPrefix)/users/\(id)"

		if let followRequest = try? await request.decode(as: APFollowRequest.self, context: context) {
			context.logger.info("follow: \(followRequest.actor)")

			guard followRequest.actor.hasPrefix("https://activitypub.academy") else {
				context.logger.info("follower unsupported")
				return Response(status: .unprocessableContent)
			}

			var actorRequest = HTTPClientRequest(url: followRequest.actor)

			actorRequest.headers.replaceOrAdd(
				name: "Accept",
				value: "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""
			)

			let client = HTTPClient.shared

			let actorResponse = try await client.execute(actorRequest, timeout: .seconds(2))
			guard actorResponse.status.code >= 200 && actorResponse.status.code < 300 else {
				context.logger.info("actor unavailable: \(actorResponse.status)")
				return Response(status: .unprocessableContent)
			}

			let body = try await actorResponse.body.collect(upTo: 1024 * 1024)
			let follower = try JSONDecoder().decode(APActor.self, from: Data(buffer: body))

			context.logger.info("follower inbox: \(follower.inbox)")
			let activityID = UUID().uuidString.lowercased()

			let accept = APAcceptActivity(
				context: "https://www.w3.org/ns/activitystreams",
				id: "\(userURLPrefix)/activity/\(activityID)",
				type: "Accept",
				actor: userURLPrefix,
				object: APAcceptActivity.Object(
					id: followRequest.id,
					type: followRequest.type,
					actor: userURLPrefix,
					object: followRequest.actor
				)
			)

			context.logger.info("accept: \(accept)")

			var acceptRequest = HTTPClientRequest(url: follower.inbox)

			let bodyBuffer = try JSONEncoder().encodeAsByteBuffer(
				accept,
				allocator: ByteBufferAllocator()
			)
			acceptRequest.body = .bytes(bodyBuffer)

			acceptRequest.method = .POST
			acceptRequest.headers.replaceOrAdd(
				name: "Content-Type",
				value: "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""
			)

			guard let components = URLComponents(string: follower.inbox, encodingInvalidCharacters: false) else {
				context.logger.info("bad follower inbox url: \(follower.inbox)")
				return Response(status: .unprocessableContent)
			}

			let url = URL(fileURLWithPath: "/opt/crosshost.pem")
			let actorPrivateKey: String

			do {
				actorPrivateKey = try String(contentsOf: url, encoding: .utf8)
			} catch {
				context.logger.info("unable to read private key: \(error)")
				return Response(status: .internalServerError)
			}

			let algoProvider = Algorithm.Provider(
				signer: { algo, data in
					precondition(algo == .RS256)

					context.logger.info("signing: \(String(decoding: data, as: UTF8.self))")

					let privateKey = try _RSA.Signing.PrivateKey(pemRepresentation: actorPrivateKey)

					let sig = try privateKey.signature(
						for: data,
						padding: _RSA.Signing.Padding.insecurePKCS1v1_5
					)

					return sig.rawRepresentation
				},
				hasher: { algo, data in
					precondition(algo == .RS256)

					context.logger.info("hashing: \(String(decoding: data, as: UTF8.self))")

					let digest = SHA256.hash(data: data)

					return Data(digest)
				}
			)

			context.logger.info("signing")

			try await acceptRequest.sign(
				scheme: components.scheme!,
				host: components.host!,
				path: components.path,
				keyId: "\(userURLPrefix)#main-key",
				provider: algoProvider
			)

			context.logger.info("http request: \(acceptRequest)")
			context.logger.info("http signature: \(acceptRequest.headers["Signature"])")
			context.logger.info("http host: \(acceptRequest.headers["Host"])")
			context.logger.info("http date: \(acceptRequest.headers["Date"])")
			context.logger.info("http digest: \(acceptRequest.headers["Digest"])")

			let acceptResponse = try await client.execute(acceptRequest, timeout: .seconds(2))

			guard acceptResponse.status.code >= 200 && acceptResponse.status.code < 300 else {
				context.logger.info("accept failed: \(acceptResponse.status)")

				let digestInput = try await acceptResponse.body.collect(upTo: 1024 * 1024)
				let data = Data(buffer: digestInput)

				let str = String(decoding: data, as: UTF8.self)
				context.logger.info("accept body: \(str)")
				return Response(status: .unprocessableContent)
			}

			context.logger.info("accepted")
		}

		return Response(status: .accepted)
	}

	func outbox(request: Request, context: Context) async throws -> Response {
		context.logger.info("outbox: \(request)")

		let id = try context.parameters.require("id")
		if id != "test" {
			return Response(status: .notFound)
		}

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
		if id != "test" {
			return Response(status: .notFound)
		}
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
