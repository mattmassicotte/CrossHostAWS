import Foundation

import AWSLambdaEvents
import AWSLambdaRuntime
import ServiceLifecycle
import SotoDynamoDB
import AsyncHTTPClient
import SotoSQS
import SotoApiGatewayManagementApi

import ATAT
import ATProto
import Shared

@main
struct LambdaFunction {
    private let logger: Logger
    private let awsClient: AWSClient
    private let dynamoDB: DynamoDB
    private let dynamoTableName: String
    private let sqs: SQS
    private let sqsURL: String
    private let managementAPI: ApiGatewayManagementApi
    private let router: Router

    static func main() async throws {
        try await LambdaFunction().main()
    }

    private init() throws {
        var logger = Logger(label: "Event")
        logger.logLevel = Lambda.env("LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
        self.logger = logger

        self.logger.info("Starting")

        let region = Region.init(awsRegionName: Lambda.env("AWS_REGION")!)!

        self.awsClient = AWSClient(httpClient: HTTPClient.shared)
        self.dynamoDB = DynamoDB(client: awsClient, region: region)
        self.dynamoTableName = Lambda.env("DYNAMO_TABLE")!

        self.sqs = SQS(client: awsClient, region: region)
        self.sqsURL = Lambda.env("EVENT_QUEUE_URL")!

        let websocketAPIEndpoint = Lambda.env("WEBSOCKET_API_URL")!
        self.managementAPI = ApiGatewayManagementApi(client: awsClient, region: region, endpoint: websocketAPIEndpoint)

        self.router = Router(managementAPI: managementAPI, logger: logger)
    }

    private func main() async throws {
        let lambdaRuntime = LambdaRuntime(logger: self.logger, body: self.handler)

        let serviceGroup = ServiceGroup(
            services: [self.awsClient, lambdaRuntime],
            gracefulShutdownSignals: [.sigterm],
            cancellationSignals: [.sigint],
            logger: self.logger
        )

        do {
            try await serviceGroup.run()
        } catch {
            logger.error("top level failure: \(error)")
            throw error
        }
    }

    private func handler(event: SQSEvent, context: LambdaContext) async throws -> Void {
        logger.info("dequeue count: \(event.records.count)")

        let payloads = try event.decodeBody(EventPayload.self)

        for payload in payloads {
            logger.info("dequeued: \(payload)")

            switch payload {
            case .webSocketConnect(id: let id, cursor: let cursor):
                try await router.registerConnection(id: id, cursor: cursor)
            case .webSocketDisconnect(id: let id):
                try await router.deregisterConnection(id: id)
            }
        }
    }
}

extension LambdaFunction {
    private func backfill(connectionId: String, cursor: Int) async throws {
        guard cursor == 300 else {
            return
        }

        logger.info("special cursor trigger!")

        try await sendData(Self.message1(), to: connectionId)
        try await sendData(Self.message2(), to: connectionId)

        logger.info("and sent")
    }

    private func sendData(_ data: Data, to connectionId: String) async throws {
        let body = AWSHTTPBody(bytes: data)

        try await managementAPI.postToConnection(
            connectionId: connectionId,
            data: body,
            logger: logger
        )
    }
}

extension LambdaFunction {
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
