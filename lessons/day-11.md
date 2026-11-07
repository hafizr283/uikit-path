# Day 11: Networking and API contracts

Build a small, testable URLSession client and understand every failure boundary.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/11/lesson) · [Course overview](../README.md)

## Outcomes

- Translate an HTTP endpoint contract into a request and Codable models.
- Distinguish transport errors, HTTP failures, and decoding failures.
- Inject URLSession and base URL so networking can be tested independently of a screen.
- Apply sensible timeouts, cancellation, and bounded retry rules.
- Keep credentials and server details out of user-facing error messages.

## Before you begin

- Day 10: async/await, cancellation, MainActor, and Sendable.
- Swift Codable, Error, URL, and basic JSON syntax.

## 1. Treat the endpoint as a contract

Before writing a request, identify its method, path, query parameters, headers, authentication rules, request body, success statuses, and error format. GET generally reads a resource; POST often creates one; PATCH partially updates; DELETE requests removal. These conventions are useful, but the actual server contract is authoritative. A successful TCP connection does not prove the application accepted your request.

Build URLs with URL and URLComponents rather than concatenating unescaped search strings. Query items handle characters such as spaces and ampersands correctly. The base URL should be injected for development, staging, production, and tests. Avoid spreading hardcoded endpoint strings through view controllers, where environment changes become difficult to review.

## 2. Decode transport data into intentional models

Codable combines Encodable and Decodable. A response model should reflect the fields your app actually needs, using CodingKeys when the server's naming differs from Swift conventions. Extra JSON keys are normally ignored. A missing nonoptional field or a mismatched type should fail decoding rather than silently inventing a value that changes the meaning of the data.

Use optionals for fields the contract truly permits to be absent or null. Do not make everything optional to hide an unstable API. Dates require a documented representation and decoder strategy, and monetary quantities deserve an explicit precision model. Keep transport DTOs separate from domain models when the app's meaning or validation differs from the server payload.

## 3. Separate three kinds of failure

A transport error means URLSession could not complete the exchange: offline connection, timeout, DNS failure, or cancellation. An HTTP failure means the server responded but returned a status your endpoint does not accept, such as 401, 404, or 503. A decoding failure means the returned bytes do not match your model contract. These require different diagnosis and often different recovery.

URLSession.data(for:) does not throw merely because the status is 404. Inspect HTTPURLResponse before decoding a success body. Keep diagnostic detail available to development logs, but display concise recovery guidance to the user. Never show raw token values, request headers, or a complete server stack trace in a screen error label.

## 4. Design a small client boundary

An API client owns request construction and response interpretation. A view controller asks for tasks and renders a result; it should not know which header spells the content type. Inject a session and base URL into the client so tests can supply a controlled transport. Later, a repository can combine this remote client with local persistence and caching.

The example uses an actor to isolate its client instance and returns immutable Sendable models. An actor does not turn every operation into parallel background work, but it provides an explicit isolation boundary. URLSession's asynchronous API suspends while waiting. Construct JSONDecoder near the operation or otherwise ensure shared mutable configuration is not accessed concurrently.

## 5. Retry only when repeating is safe

Set request timeouts appropriate to the user action, and let cancellation propagate. A bounded retry may be reasonable for a transient failure on an idempotent read, using a small backoff and respecting server guidance such as Retry-After. Do not retry every failure: a malformed response, invalid credential, or nonexistent resource will rarely improve through immediate repetition.

A POST can create a duplicate if the first request succeeded but its response was lost. Retrying writes requires a server-supported idempotency key or another explicit contract. Similarly, authentication refresh belongs in a coordinated session mechanism rather than a recursive request loop with no limit. Each retry policy should state which errors it accepts, its maximum attempts, and how cancellation interrupts waiting.

## Worked example: Fetch typed tasks with a reusable client

**File:** TaskAPI.swift

```swift
import Foundation

struct RemoteTask: Decodable, Sendable, Identifiable {
    let id: Int
    let title: String
    let completed: Bool
}

enum APIError: Error {
    case invalidURL
    case nonHTTPResponse
    case httpStatus(Int)
}

actor TaskAPI {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchTasks(limit: Int = 20) async throws -> [RemoteTask] {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("todos"),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "_limit", value: String(max(1, min(limit, 100))))
        ]
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw APIError.nonHTTPResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.httpStatus(response.statusCode)
        }
        return try JSONDecoder().decode([RemoteTask].self, from: data)
    }
}

// Call from an async context. This public demo API contains sample data.
// Do not send personal data or production credentials to it.
func loadDemoTasks() async throws -> [RemoteTask] {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com") else {
        throw APIError.invalidURL
    }
    let api = TaskAPI(baseURL: url)
    return try await api.fetchTasks(limit: 5)
}
```

### Walkthrough and setup

1. Add TaskAPI.swift to an iOS app or a Foundation-capable Swift target. The public JSONPlaceholder endpoint is a third-party demonstration service; network availability and its data are outside this course's control.
2. Call try await loadDemoTasks() from the Task started by your UIKit screen. Keep rendering on MainActor and handle cancellation separately from actionable failures.
3. RemoteTask includes only the fields the interface uses. JSONPlaceholder's additional userId field can be ignored by Decodable.
4. The client builds the query using URLComponents, checks HTTP status, then decodes a success payload. URLError and DecodingError are intentionally preserved rather than collapsed into one unknown error.
5. The initializer accepts URLSession and baseURL so later tests can inject a controlled configuration. A production app should point to its authorized backend and implement that backend's exact contract.

**Expected behavior:** With an available demo service, the async call returns up to five RemoteTask values. Offline transport, unsuccessful status, or incompatible JSON throws an error for the caller to handle.

## Challenge 1: Map snake_case JSON without optionalizing everything

**Level:** Warm-up

Decode a JSON task with task_id, task_title, and due_date. The first two fields are required; the due date is an optional ISO 8601 timestamp.

### Requirements

- Use CodingKeys to map server names.
- Configure an ISO 8601 date-decoding strategy.
- Keep id and title nonoptional.

### Starter

```swift
struct TaskDTO: Decodable {
    // Add fields and CodingKeys.
}
// Decode one fixture with a missing due_date.
```

<details>
<summary>Hints</summary>

- A missing optional property decodes as nil.
- JSONDecoder.dateDecodingStrategy controls Date parsing.

</details>

### Acceptance checks

- The fixture produces id 7, the expected title, and nil dueDate.
- Removing task_title throws a decoding error.
- A contract-compatible ISO 8601 timestamp decodes to a Date.

<details>
<summary>Worked solution</summary>

```swift
struct TaskDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let dueDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case title = "task_title"
        case dueDate = "due_date"
    }
}

func decodeFixture() throws -> TaskDTO {
    let data = Data(#"{"task_id":7,"task_title":"Read the API contract"}"#.utf8)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(TaskDTO.self, from: data)
}
```

The type documents which fields are guaranteed and which may be absent. For a backend with fractional timestamps or multiple date representations, implement and test that specific format instead of assuming every ISO-like string is accepted by one strategy.

</details>

## Challenge 2: Encode a POST body

**Level:** Core

Add a createTask(title:) method to TaskAPI. Encode JSON, set Content-Type, validate the status, and decode the returned task.

### Requirements

- Use an Encodable request type.
- Reject a blank title before sending.
- Preserve cancellation and transport failures.
- Treat the public demo endpoint as simulated persistence.

### Starter

```swift
// Add inside TaskAPI.
func createTask(title: String) async throws -> RemoteTask {
    // Encode, send, validate, decode.
    throw APIError.invalidURL
}
```

<details>
<summary>Hints</summary>

- The URL is baseURL.appendingPathComponent("todos").
- The response model may ignore extra fields from the server.

</details>

### Acceptance checks

- Blank input fails locally.
- The encoded body contains a trimmed title and completed false.
- A returned 4xx or 5xx is handled before success decoding.
- Explain why this POST should not be blindly retried after a lost response.

<details>
<summary>Worked solution</summary>

```swift
// Add alongside the other request models.
struct NewTask: Encodable, Sendable {
    let title: String
    let completed: Bool
    let userId: Int
}

enum TaskInputError: Error { case blankTitle }

// Add this method inside TaskAPI.
func createTask(title: String) async throws -> RemoteTask {
    let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { throw TaskInputError.blankTitle }
    var request = URLRequest(url: baseURL.appendingPathComponent("todos"))
    request.httpMethod = "POST"
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = try JSONEncoder().encode(
        NewTask(title: cleaned, completed: false, userId: 1)
    )
    let (data, response) = try await session.data(for: request)
    try Task.checkCancellation()
    guard let response = response as? HTTPURLResponse else {
        throw APIError.nonHTTPResponse
    }
    guard (200..<300).contains(response.statusCode) else {
        throw APIError.httpStatus(response.statusCode)
    }
    return try JSONDecoder().decode(RemoteTask.self, from: data)
}
```

Content-Type describes the body being sent; Accept describes the desired response format. JSONPlaceholder acknowledges sample writes but does not persist them as your real backend would. Do not conclude that a later GET must contain this task. Test production persistence only against the intended server contract.

</details>

## Challenge 3: Bound retries for a transient read failure

**Level:** Stretch

Write a wrapper that retries fetchTasks at most twice after the initial attempt, but only for HTTP 503. Preserve all other failures and allow cancellation during the backoff.

### Requirements

- Use a maximum of three total attempts.
- Use increasing, cancellable delays.
- Never retry decoding failures, 401, or cancellation.
- Keep the policy specific to this idempotent read.

### Starter

```swift
func fetchWithRetry(api: TaskAPI) async throws -> [RemoteTask] {
    // Three attempts maximum.
    return []
}
```

<details>
<summary>Hints</summary>

- Count failures and compare before waiting.
- Task.sleep throws if the task is cancelled.

</details>

### Acceptance checks

- A 503 followed by success performs two attempts.
- Three 503 responses result in an error without a fourth attempt.
- A decoding failure or 401 makes one attempt.
- Cancelling during a delay exits immediately through cancellation.

<details>
<summary>Worked solution</summary>

```swift
func fetchWithRetry(api: TaskAPI) async throws -> [RemoteTask] {
    var failures = 0
    while true {
        try Task.checkCancellation()
        do {
            return try await api.fetchTasks()
        } catch APIError.httpStatus(503) {
            failures += 1
            guard failures < 3 else { throw APIError.httpStatus(503) }
            try await Task.sleep(for: .milliseconds(250 * failures))
        } catch {
            throw error
        }
    }
}
```

This intentionally small policy is easy to audit: only 503 is retried, there are at most three attempts, and waiting cooperates with cancellation. A production policy may also honor Retry-After and add jitter, but should retain explicit bounds and distinguish safe reads from writes.

</details>

## Knowledge check

### 1. What happens when URLSession receives an HTTP 404 response?

A. data(for:) always throws URLError automatically

B. You must inspect the HTTP status and apply the endpoint contract

C. The response is automatically decoded as nil

D. The request retries forever

<details>
<summary>Answer and explanation</summary>

**B. You must inspect the HTTP status and apply the endpoint contract**

An HTTP response can be a successful transport exchange but an application-level failure. Check HTTPURLResponse before decoding the success model.

</details>

### 2. What is the purpose of Accept: application/json?

A. It says the request body is JSON

B. It requests a JSON response representation

C. It authenticates the user

D. It disables TLS

<details>
<summary>Answer and explanation</summary>

**B. It requests a JSON response representation**

Accept expresses desired response formats. Content-Type describes the representation of a body being sent.

</details>

### 3. Why use URLComponents for a search query?

A. It makes requests synchronous

B. It handles query-item encoding correctly

C. It stores passwords securely

D. It guarantees the server is online

<details>
<summary>Answer and explanation</summary>

**B. It handles query-item encoding correctly**

Manually joining user input into a URL can misinterpret spaces, ampersands, and other reserved characters. Query items express the intended components safely.

</details>

### 4. Which field should normally be optional in a response model?

A. Every field, to prevent all decoding errors

B. Only fields allowed to be absent or null by the contract

C. Only integer fields

D. No field can be optional

<details>
<summary>Answer and explanation</summary>

**B. Only fields allowed to be absent or null by the contract**

Optionality should model the API's meaning. Making required fields optional hides contract failures and spreads uncertainty through the app.

</details>

### 5. Why can retrying a POST after a timeout be dangerous?

A. POST never uses HTTP

B. The server may already have created the resource before the response was lost

C. JSON cannot be encoded twice

D. Every timeout means the request was never sent

<details>
<summary>Answer and explanation</summary>

**B. The server may already have created the resource before the response was lost**

The client may not know whether the write succeeded. Safe repetition requires an explicit server contract, often an idempotency key.

</details>

## Common pitfalls

- Decoding an HTTP error body as if it were the success model.
- Making required fields optional to conceal schema mismatch.
- Building URLs by concatenating unescaped user input.
- Logging authorization headers or tokens.
- Retrying writes without an idempotency contract.
- Assuming a public demo API persists mutations or is always available.

## PocketTasks milestone: PocketTasks milestone: a real API boundary

1. Add a TaskAPI separate from your view controllers.
2. Decode controlled fixtures for success and malformed responses.
3. Connect a read-only demo endpoint or your company's approved development backend.
4. Document the contract and keep a mock service available for deterministic learning.

## Before you move on

- Explain one transport, HTTP, and decoding failure separately.
- Construct a query containing spaces and ampersands correctly.
- Decode a fixture before depending on a live server.
- Show where base URL and URLSession are injected.
- Describe the maximum attempts and accepted errors of your retry policy.

## Official references

- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [URLRequest](https://developer.apple.com/documentation/foundation/urlrequest)
- [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder)
- [URLComponents](https://developer.apple.com/documentation/foundation/urlcomponents)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
