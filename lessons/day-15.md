# Day 15: Authentication & session management

Keep credentials private and session state predictable.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/15/lesson) · [Course overview](../README.md)

## Outcomes

- Explain access tokens, refresh tokens, and server-side authorization.
- Store a refresh token in Keychain without treating UserDefaults as secret storage.
- Coordinate expired-session handling and simultaneous refresh requests.
- Design login, restoration, logout, and account-switch transitions.

## Before you begin

- Day 10: actors, tasks, cancellation, and MainActor.
- Day 11: URLSession, HTTP status handling, and Codable.
- Day 13: injected services and a single source of truth.

## 1. Authentication is a state machine

Authentication answers who the server believes you are; authorization answers which actions that identity may perform. A hidden button is a UI choice, not an authorization boundary. The backend must check permissions on every protected operation. Your iOS app represents that server relationship with explicit states such as restoring, signedOut, signingIn, signedIn, and expired. Model those states rather than scattering an isLoggedIn Boolean across controllers.

At launch, display a restoration state while you examine stored credentials and ask the server for an acceptable session. A stored token does not prove that the account still exists or that the token remains valid. Network failure during restoration is also different from a server rejecting the credential. Keep a retry path and decide deliberately which cached account data can be shown offline. On logout, clear account-specific caches, cancel requests, remove stored credentials, and replace the protected navigation hierarchy.

## 2. Understand token boundaries

An access token is usually short lived and accompanies protected API requests. A refresh token can obtain a replacement access token and is consequently a valuable credential. Exact expiration and rotation rules belong to the service contract. Do not assume all tokens are JWTs, decode a token and call the contents trusted, or invent your own password protocol. A token is still untrusted until the server validates it.

Use HTTPS and attach an Authorization header only to the intended API origin. Never put secrets in URLs, screenshots, analytics, print statements, or source control. A mobile app cannot keep an embedded client secret confidential. For an OAuth or OpenID Connect service, use its supported authorization-code flow with PKCE and a system web-authentication session, including state/nonce validation appropriate to that flow. A practice email form and an in-memory mock server are useful exercises, but they do not implement a production identity provider.

## 3. Persist the minimum in Keychain

UserDefaults and ordinary JSON files are suitable for preferences and non-secret data; they are not appropriate places for refresh tokens. Keychain provides platform-managed storage and an accessibility policy. The example chooses WhenUnlockedThisDeviceOnly: the item is available while the device is unlocked and does not migrate to another device. Select a different policy only when the product's documented background-access requirements justify it.

A Keychain item has an identity, here a service and account pair. Updating data is different from creating an item, and a missing item is a normal signed-out condition. Other errors, such as unavailable interaction, must remain visible to the caller. An actor serializes this helper's operations, but it does not automatically solve session lifecycle races elsewhere. Never log the stored value while debugging the helper; log a safe operation name and an error code instead.

## 4. Refresh once, retry deliberately

Many requests may discover expiration at the same moment. Starting a refresh for each can cause duplicate work or invalidate rotated refresh tokens. Give one session service ownership of an in-flight refresh task so callers can await the same result. Remember that actors are reentrant across await: another method can run while a refresh is suspended. Use a generation or session identifier to prevent a response from an old account from being installed after logout or account switching.

A refresh failure should not create an infinite 401 loop. Refresh at most once for an eligible request, then surface rejection if the retry is unauthorized. Decide whether the original operation is safe to repeat: a timed-out payment POST may already have succeeded. An idempotency key and server support can make selected mutations retryable. Distinguish cancellation, connectivity failure, forbidden access, and expired authentication; mapping every failure to logout produces a frustrating and misleading app.

## 5. Keep authentication out of view controllers

A login controller should gather input, show validation and progress, and render a result. Inject an authentication service rather than letting each screen read Keychain or build refresh requests. Keep credentials out of view-model debug descriptions. Disable duplicate submissions while an operation is active, use secure text entry for passwords, and show errors without revealing whether an unrelated person's account exists.

At the root, observe session state on MainActor and choose the signed-out or protected flow. When a token expires, preserve a non-secret description of the user's intended destination if the product allows it. After a successful login, validate that destination again before opening it. Test restoration with no token, a valid token, a rejected token, airplane mode, concurrent requests, and logout during refresh. These boundaries are more valuable than a login screen that only works on the happy path.

## Worked example: A small Keychain refresh-token store

**File:** RefreshTokenStore.swift

```swift
import Foundation
import Security

enum TokenStoreError: Error {
    case status(OSStatus)
    case invalidData
}

actor RefreshTokenStore {
    private let service: String
    private let account = "refresh-token"

    init(service: String) {
        self.service = service
    }

    private var identity: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func save(_ token: String) throws {
        let data = Data(token.utf8)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(
            identity as CFDictionary,
            update as CFDictionary
        )
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw TokenStoreError.status(status)
        }

        var item = identity
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] =
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else {
            throw TokenStoreError.status(added)
        }
    }

    func read() throws -> String? {
        var query = identity
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary, &result
        )
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw TokenStoreError.status(status)
        }
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else { throw TokenStoreError.invalidData }
        return token
    }

    func delete() throws {
        let status = SecItemDelete(identity as CFDictionary)
        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw TokenStoreError.status(status)
        }
    }
}
```

### Walkthrough and setup

1. Add this file to an iOS app target. It uses Foundation and Security and does not depend on a storyboard or SwiftUI.
2. Create one store with a stable reverse-DNS service such as com.example.PocketTasks.auth. Use a unique service in each test so exercises cannot overwrite a real account's item.
3. Call try await store.save("fixture-only"), then try await store.read(), and finally try await store.delete() from an async function. Compare values in a test; do not print real tokens.
4. The update-first path handles replacing an existing token. A missing item falls back to add, with an explicit device-local accessibility policy.
5. This stores one refresh token. Multiple accounts, access groups, refresh-token rotation, biometric access control, and the server exchange need additional product-specific design.

**Expected behavior:** A saved fixture can be read; saving again replaces it; reading after deletion returns nil. All non-missing Keychain failures are thrown.

## Challenge 1: Make expiry logic deterministic

**Level:** Warm-up

A request should proactively refresh when its access token is within 30 seconds of expiration. Write a pure value type so you can test exact boundary times without waiting for the clock.

### Requirements

- Inject the current Date into the decision.
- Treat the exact boundary as needing refresh.
- Keep the raw token out of descriptions and output.

### Starter

```swift
import Foundation
struct AccessCredential {
    let value: String
    let expiresAt: Date
    func needsRefresh(at now: Date) -> Bool {
        // Compare against a 30-second allowance.
        false
    }
}
```

<details>
<summary>Hints</summary>

- Date supports timeIntervalSince(_:).
- A remaining lifetime of exactly 30 seconds belongs to the refresh case.

</details>

### Acceptance checks

- A token expiring in 31 seconds returns false.
- A token expiring in 30 seconds returns true.
- An already expired token returns true.

<details>
<summary>Worked solution</summary>

```swift
import Foundation
struct AccessCredential {
    let value: String
    let expiresAt: Date

    func needsRefresh(at now: Date) -> Bool {
        expiresAt.timeIntervalSince(now) <= 30
    }
}
```

Time is a dependency even when it looks like a global utility. Passing now makes expiration behavior reproducible. This allowance reduces near-expiry failures but cannot replace server-side validation.

</details>

## Challenge 2: Build a safe authorized request

**Level:** Core

Create a GET request for one known HTTPS API origin. Reject a URL from another host or port so a caller cannot accidentally attach a token to an unrelated image URL.

### Requirements

- Accept only https://api.example.com with no non-default port.
- Reject embedded username/password credentials.
- Use an Authorization header and never a query token.
- Keep the function pure so tests can inspect the URLRequest.

### Starter

```swift
import Foundation
enum RequestError: Error { case untrustedURL }
func authorizedGET(url: URL, token: String) throws -> URLRequest {
    // Validate the destination before attaching the token.
    URLRequest(url: url)
}
```

<details>
<summary>Hints</summary>

- URL exposes scheme, host, port, user, and password.
- HTTPS's default port is 443; a nil port also means the default.

</details>

### Acceptance checks

- An HTTPS URL at the exact API host is accepted.
- HTTP, api.example.com.evil.test, and port 8443 are rejected.
- The token is present in the header and absent from the URL.

<details>
<summary>Worked solution</summary>

```swift
import Foundation
enum RequestError: Error { case untrustedURL }

func authorizedGET(url: URL, token: String) throws -> URLRequest {
    guard url.scheme?.lowercased() == "https",
          url.host?.lowercased() == "api.example.com",
          url.port == nil || url.port == 443,
          url.user == nil, url.password == nil
    else { throw RequestError.untrustedURL }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)",
                     forHTTPHeaderField: "Authorization")
    return request
}
```

Credential attachment should have an explicit destination boundary. This exercise constructs a request only; a production client must also define redirect handling and avoid forwarding credentials outside the trusted origin. Use a fixture token during inspection.

</details>

## Challenge 3: Share one refresh task and invalidate it on logout

**Level:** Stretch

Implement an actor that shares a single refresh operation. For this exercise the injected refresh closure returns a fixture access token; it does not contact an identity provider or persist a rotated refresh token.

### Requirements

- Two simultaneous callers share the in-flight task.
- logout() cancels the task and advances a generation.
- A pre-logout result must never be returned as a current credential.
- Let callers handle refresh errors; do not swallow them.

### Starter

```swift
import Foundation
actor RefreshCoordinator {
    // Store a task and a session generation here.
}
```

<details>
<summary>Hints</summary>

- Store Task<String, Error>? in the actor.
- Record the generation before await and check it afterward.
- Use a monotonically changing attempt ID so an old waiter cannot clear a newer in-flight task.

</details>

### Acceptance checks

- Inject a counted delayed closure; concurrent token() calls invoke it once.
- Call logout before the delayed closure completes; awaiting callers fail.
- After logout, a new call can start a new task without an old waiter clearing it.

<details>
<summary>Worked solution</summary>

```swift
import Foundation

actor RefreshCoordinator {
    private var inFlight: Task<String, Error>?
    private var generation = 0
    private var attempt = 0
    private let refresh: @Sendable () async throws -> String

    init(refresh: @escaping @Sendable () async throws -> String) {
        self.refresh = refresh
    }

    func token() async throws -> String {
        let startedGeneration = generation
        if inFlight == nil {
            attempt += 1
            let operation = refresh
            inFlight = Task { try await operation() }
        }
        let startedAttempt = attempt
        guard let task = inFlight else {
            throw CancellationError()
        }

        do {
            let result = try await task.value
            guard generation == startedGeneration else {
                throw CancellationError()
            }
            if attempt == startedAttempt { inFlight = nil }
            return result
        } catch {
            if generation == startedGeneration &&
                attempt == startedAttempt {
                inFlight = nil
            }
            throw error
        }
    }

    func logout() {
        generation += 1
        inFlight?.cancel()
        inFlight = nil
    }
}
```

Actor serialization does not extend across an await. The generation prevents the old session from surviving logout, while the attempt guard prevents an older waiter from clearing a later task. The shared task is cancelled by logout, not automatically by one waiting caller. Production token rotation must also guard its persistence step against an old generation.

</details>

## Knowledge check

### 1. Which location is appropriate for a long-lived refresh token?

A. UserDefaults

B. A bundled JSON file

C. Keychain with a deliberate accessibility policy

D. An analytics user property

<details>
<summary>Answer and explanation</summary>

**C. Keychain with a deliberate accessibility policy**

Keychain is designed for credentials. Its accessibility and sharing settings must match the product requirements.

</details>

### 2. Why can a logout race still occur inside an actor?

A. Actors never serialize methods

B. An actor can run another method while a method awaits

C. Keychain always logs out automatically

D. Only UIKit classes support cancellation

<details>
<summary>Answer and explanation</summary>

**B. An actor can run another method while a method awaits**

Actors are reentrant at suspension points. Validate the session generation after asynchronous work.

</details>

### 3. An API returns 403 for a signed-in account. What should you assume?

A. Refresh forever

B. The request is necessarily offline

C. The account may lack permission for this operation

D. The token must be stored in a URL

<details>
<summary>Answer and explanation</summary>

**C. The account may lack permission for this operation**

A forbidden response often represents authorization failure. Follow the service contract rather than treating every rejection as token expiry.

</details>

### 4. Why is blindly retrying a timed-out purchase POST dangerous?

A. POST bodies cannot be encoded

B. The server may already have processed it

C. HTTPS cannot carry POST

D. A timeout proves the server did nothing

<details>
<summary>Answer and explanation</summary>

**B. The server may already have processed it**

The response can be lost after the mutation succeeds. Use appropriate server idempotency semantics before retrying.

</details>

### 5. What does a token found at launch prove?

A. The account is still authorized

B. The token never expires

C. The app has stored credential material that still needs validation

D. The user entered a password today

<details>
<summary>Answer and explanation</summary>

**C. The app has stored credential material that still needs validation**

Local presence says nothing about server-side revocation or account status.

</details>

## Common pitfalls

- A Boolean login flag can disagree with the actual server session.
- Deleting the credential without clearing account caches can expose the previous user's data.
- Logging requests without redaction can leak Authorization headers.
- A refresh task can complete after logout or account switching.
- An embedded client secret in an iOS binary is not a confidential server secret.

## PocketTasks milestone: Give PocketTasks an explicit session boundary

1. Use a mock AuthService to build signed-out, restoring, and signed-in flows without collecting real credentials.
2. Store only a fixture refresh token in the example Keychain service.
3. Clear fixture tasks and protected navigation on logout.
4. Document where production OAuth configuration, redirect policy, token rotation, and server authorization would be added.

## Before you move on

- Explain how a protected screen is chosen during restoration.
- Demonstrate fixture save, replace, read, and deletion in Keychain.
- Describe the difference between a 401, a 403, and a connectivity failure.
- Explain how your design rejects a stale refresh result after logout.
- Identify which requests may be safely retried and why.

## Official references

- [Apple: Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Apple: ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
- [Swift: Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
