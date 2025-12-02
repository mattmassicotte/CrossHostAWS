import Foundation

import AWSLambdaEvents
import AWSLambdaRuntime
import ServiceLifecycle
import SotoDynamoDB
import AsyncHTTPClient
import SotoSQS

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

    static func main() async throws {
        try await LambdaFunction().main()
    }

    private init() throws {
        var logger = Logger(label: "WebSocket")
        logger.logLevel = Lambda.env("LOG_LEVEL").flatMap(Logger.Level.init) ?? .info
        self.logger = logger

        let region = Region.init(awsRegionName: Lambda.env("AWS_REGION")!)!

        self.awsClient = AWSClient(httpClient: HTTPClient.shared)
        self.dynamoDB = DynamoDB(client: awsClient, region: region)
        self.dynamoTableName = Lambda.env("DYNAMO_TABLE")!

        self.sqs = SQS(client: awsClient, region: region)
        self.sqsURL = Lambda.env("EVENT_QUEUE_URL")!
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

    private func handler(event: APIGatewayWebSocketRequest, context: LambdaContext) async throws -> APIGatewayWebSocketResponse {
        let connectionId = event.context.connectionId

        logger.info("\(event.context.routeKey) \(connectionId) \(event.queryStringParameters ?? [:])")

        let cursorParam = event.queryStringParameters?["cursor"] ?? "0"
        let cursor = Int(cursorParam) ?? 0

        switch event.context.routeKey {
        case "$connect":
            try await addClient(connectionId, cursor: cursor)
            try await enqueueEvent(.webSocketConnect(id: connectionId, cursor: cursor))

        case "$disconnect":
            try await removeClient(connectionId)
            try await enqueueEvent(.webSocketDisconnect(id: connectionId))

        default:
            break
        }

        return APIGatewayWebSocketResponse(statusCode: .ok)
    }
}

extension LambdaFunction {
    private func addClient(_ connectionId: String, cursor: Int) async throws {
        let time = Int(Date.now.timeIntervalSince1970)
        let record = WebSocketClientRecord(connectionId: connectionId, timestamp: time, cursor: cursor)
        let input = DynamoDB.PutItemCodableInput(item: record, tableName: self.dynamoTableName)
        _ = try await dynamoDB.putItem(input, logger: self.logger)
    }

    private func removeClient(_ requestId: String) async throws {
        let input = DynamoDB.DeleteItemInput(
            key: ["pk": .s(WebSocketClientRecord.name), "sk": .s(requestId)],
            tableName: self.dynamoTableName
        )
        _ = try await dynamoDB.deleteItem(input)

    }

    private func enqueueEvent(_ event: EventPayload) async throws {
        let eventBody = try JSONEncoder().encode(event)

        let sqsInput = SQS.SendMessageRequest(
            messageBody: String(decoding: eventBody, as: UTF8.self),
            queueUrl: self.sqsURL
        )

        _ = try await sqs.sendMessage(sqsInput, logger: logger)
    }
}
