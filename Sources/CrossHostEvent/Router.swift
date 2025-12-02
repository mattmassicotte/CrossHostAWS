import Foundation
import Logging

import SotoApiGatewayManagementApi
import ATAT
import ATProto

actor Router {
    private let logger: Logger
    private let managementAPI: ApiGatewayManagementApi
    private var connections: [String: Int] = [:]
    private var currentSeq = 2

    init(managementAPI: ApiGatewayManagementApi, logger: Logger) {
        self.managementAPI = managementAPI
        self.logger = logger
    }

    func registerConnection(id: String, cursor: Int) async throws {
        self.connections[id] = cursor

        if cursor == currentSeq {
            logger.info("client \(id) is caught up \(currentSeq)")
            return
        }

        if cursor > currentSeq {
            logger.warning("client \(id) cursor is greater than current \(currentSeq)")
            return
        }


        logger.warning("client \(id) backfill needed: \(currentSeq) > \(cursor)")

//        return

        let backfillSequence = try eventSequence(for: cursor)

        do {
            for await data in backfillSequence {
                try await self.sendData(data, to: id)
            }
        } catch {
            logger.error("client \(id) backfill failed: \(error)")

            await closeConnection(id: id)
        }

        logger.info("client \(id) backfill complete")
    }

    func deregisterConnection(id: String) async throws {
    }

    func closeConnection(id: String) async {
        logger.warning("client \(id) closeConnection not implemented")
    }

    private func sendData(_ data: Data, to connectionId: String) async throws {
        let body = AWSHTTPBody(bytes: data.base64EncodedData())

        try await managementAPI.postToConnection(
            connectionId: connectionId,
            data: body,
            logger: logger
        )
    }

    private func eventSequence(for cursor: Int) throws -> some AsyncSequence<Data, Never> {
        let messages = [
            try Self.message1(),
            try Self.message2()
        ]

        return messages.suffix(from: cursor).async
    }
}

extension Router {
    static func message1() throws -> Data {
        let date = Date(timeIntervalSince1970: 1761709682)

        let message = ATProto.Sync.SubscribeRepos.Message(
            header: ATProto.Sync.SubscribeRepos.Header(op: 1, t: "#identity"),
            payload: ATProto.Sync.SubscribeRepos.Identity(
                did: "web:did:social.massicotte.org",
                handle: "social.massicotte.org",
                seq: 1,
                time: ATProto.iso8061DecimalDecoder.string(from: date)
            )
        )

        return try message.dagCBOREncoded()
    }

    static func message2() throws -> Data {
        let date = Date(timeIntervalSince1970: 1761709683)

        let message = ATProto.Sync.SubscribeRepos.Message(
            header: ATProto.Sync.SubscribeRepos.Header(op: 1, t: "#account"),
            payload: ATProto.Sync.SubscribeRepos.Account(
                did: "web:did:social.massicotte.org",
                active: true,
                seq: 2,
                time: ATProto.iso8061DecimalDecoder.string(from: date),
                status: nil
            )
        )

        return try message.dagCBOREncoded()
    }
}
