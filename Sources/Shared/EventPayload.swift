public enum EventPayload: Codable {
    case webSocketConnect(id: String, cursor: Int)
    case webSocketDisconnect(id: String)

    public var clientId: String {
        switch self {
        case .webSocketConnect(id: let id, cursor: _):
            id
        case .webSocketDisconnect(id: let id):
            id
        }
    }
}
