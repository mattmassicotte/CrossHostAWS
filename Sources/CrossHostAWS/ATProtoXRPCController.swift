import Foundation

import ATAT
import CrossHost
import Hummingbird
import HummingbirdWebSocket
import ATProto
import Crypto

public struct ATProtoTID: Codable, Hashable, Sendable {
	public init() {
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()

		try container.encode(description)
	}
}

extension ATProtoTID: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
	}
}

extension ATProtoTID: CustomStringConvertible {
	public var description: String {
		"3jzfcijpj2z2a"
	}
}

extension ATProto {
	public struct Sync {
		public struct Repo: Codable, Hashable, Sendable {
			public enum Status: String, Codable, Hashable, Sendable {
				case takendown
				case suspended
				case deleted
				case deactivated
				case desynchronized
				case throttled
			}

			public let did: ATProtoDID
			public let head: ATProtoCID
			public let rev: ATProtoTID
			public let active: Bool
			public let status: Status?
		}

		public struct ListRepos: Codable, Hashable, Sendable {
			public let repos: [Repo]
			public let cursor: String?

			public init(repos: [Repo], cursor: String?) {
				self.repos = repos
				self.cursor = cursor
			}
		}
	}
}

extension CID {
	public init(_ data: Data) throws {
		try self.init { multihash in
			switch (multihash.function, multihash.digestSize) {
			case (.SHA2, 256):
				let digest = SHA256.hash(data: data)

				return Data(digest)
			default:
				throw CIDError.unsupportedCodec(Int(multihash.function.rawValue))
			}
		}
	}
}

extension RequestContext {
	func jsonResponse<T: Encodable>(_ value: T, for request: Request) throws -> Response {
		var response = try responseEncoder.encode(value, from: request, context: self)

		response.headers[.contentType] = "application/json; charset=utf-8;"

		return response
	}
}

public struct ATProtoXRPCController<Context: RequestContext>: Sendable {
	let configuration: ControllerConfiguration

	public init(configuration: ControllerConfiguration) {
		self.configuration = configuration
	}

	public var endpoints: RouteCollection<Context> {
		RouteCollection(context: Context.self)
			.get("/xrpc/com.atproto.repo.describeRepo", use: repoDescribeRepo)
			.get("/xrpc/com.atproto.repo.getRecord", use: repoGetRecord)
			.get("/xrpc/com.atproto.repo.listRecords", use: repoListRecords)
			.get("/xrpc/com.atproto.server.describeServer", use: serverDescribeServer)
			.get("/xrpc/com.atproto.sync.getRecord", use: syncGetRecord)
			.get("/xrpc/com.atproto.sync.listRepos", use: syncListRepos)
			.get("/xrpc/_health", use: health)
			.get("/xrpc/:nsid", use: getResource)
			.post("/xrpc/:nsid", use: createResource)
	}

	func repoDescribeRepo(request: Request, context: some RequestContext) async throws -> Response {
		let repo = try request.uri.queryParameters.require("repo")

		context.logger.info("repoDescribeRepo: \(repo) \(request)")

		guard repo == "did:web:\(configuration.host)" || repo == configuration.host else {
			context.logger.warning("Unexpected repo")

			return Response(status: .notFound)
		}

		let didDoc = try DIDWebController<Context>.DIDDocument(with: configuration.host, key: configuration.p256KeyPem)

		let content = ATProto.Repo.DescribeRepo(
			handle: configuration.host,
			did: "did:web:\(configuration.host)",
			didDoc: didDoc,
			collections: [],
			handleIsCorrect: true
		)

		return try context.jsonResponse(content, for: request)
	}

	func repoGetRecord(request: Request, context: some RequestContext) async throws -> Response {
		let repo = try request.uri.queryParameters.require("repo")
		let collection = try request.uri.queryParameters.require("collection")
		let rkey = try request.uri.queryParameters.require("rkey")
		let cid = request.uri.queryParameters.get("cid") ?? "<none>"

		context.logger.info("repoGetRecord: \(repo), \(collection), \(rkey), \(cid)  \(request)")

		return Response(status: .notImplemented)
	}

	func repoListRecords(request: Request, context: some RequestContext) async throws -> Response {
		let repo = try request.uri.queryParameters.require("repo")
		let collection = try request.uri.queryParameters.require("collection")
		let limit = request.uri.queryParameters.get("limit") ?? "50"
		let cursor = request.uri.queryParameters.get("cursor") ?? "<none>"
		let reverse = request.uri.queryParameters.get("reverse") ?? "false"

		context.logger.info("repoListRecords: \(repo), \(collection), \(limit), \(cursor) \(reverse) \(request)")

		return Response(status: .notImplemented)
	}

	func serverDescribeServer(request: Request, context: some RequestContext) async throws -> Response {
		let content = ATProto.Server.DescribeServer(
			did: "did:web:\(configuration.host)",
			availableUserDomains: ["." + configuration.host],
			inviteCodeRequired: true,
			phoneVerificationRequired: nil,
			contact: ATProto.Server.DescribeServer.Contact(email: nil),
			links: nil
		)

		return try context.jsonResponse(content, for: request)
	}

	func syncGetRecord(request: Request, context: some RequestContext) async throws -> Response {
		let repo = try request.uri.queryParameters.require("repo")
		let collection = try request.uri.queryParameters.require("collection")
		let rkey = try request.uri.queryParameters.require("rkey")

		context.logger.info("repoGetRecord: \(repo), \(collection), \(rkey) \(request)")

		return Response(status: .notImplemented)
	}

	func syncListRepos(request: Request, context: some RequestContext) async throws -> Response {
		let limit = request.uri.queryParameters.get("limit") ?? "500"
		let cursor = request.uri.queryParameters.get("cursor") ?? "<none>"

		context.logger.info("syncListRepos: \(limit), \(cursor) \(request)")

		let cid = try CID(Data("abc".utf8))

		let repos = ATProto.Sync.ListRepos(
			repos: [
				ATProto.Sync.Repo(
					did: "did:web:\(configuration.host)",
					head: cid.baseEncodedString(),
					rev: ATProtoTID(),
					active: true,
					status: nil
				)
			],
			cursor: nil
		)

		return try context.jsonResponse(repos, for: request)
	}

	func health(request: Request, context: some RequestContext) async throws -> Response {
		Response(status: .ok)
	}

	private func getResource(request: Request, context: some RequestContext) async throws -> Response {
		Response(status: .notImplemented)
	}

	private func createResource(request: Request, context: some RequestContext) async throws -> Response {
		Response(status: .notImplemented)
	}
}
