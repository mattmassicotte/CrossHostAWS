public struct WebSocketClientRecord: Codable, Sendable {
    public static let name = "WEBSOCKET_CLIENT"

    public let id = WebSocketClientRecord.name
    public let connectionId: String

    public let timestamp: Int
    public let cursor: Int

    enum CodingKeys: String, CodingKey {
        case id = "pk"
        case connectionId = "sk"

        case timestamp
        case cursor
    }

    public init(connectionId: String, timestamp: Int, cursor: Int) {
        self.connectionId = connectionId
        self.timestamp = timestamp
        self.cursor = cursor
    }
}
