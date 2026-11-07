// Worked solution: Define valid screen states
// This enum prevents an impossible combination such as initial loading plus a final error flag. It also describes the product decision that a refresh failure may retain previous content. Your renderer should show an inline message when previous is nonempty and a full error state when it is empty.
// Read lessons/day-12.md for any surrounding types or setup.

enum InboxState {
    case idle
    case loading
    case content([RemoteTask])
    case refreshing([RemoteTask])
    case failed(message: String, previous: [RemoteTask])
}
