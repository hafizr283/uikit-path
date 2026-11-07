// Worked solution: Protect a shared counter with an actor
// Child tasks may execute in any order. The actor serializes access to its isolated value, and the group scope waits for completion. Serialization here protects a tiny state mutation; placing all expensive unrelated work inside one actor could unnecessarily reduce throughput.
// Read lessons/day-10.md for any surrounding types or setup.

actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func currentValue() -> Int { value }
}

func countCompletedWork() async -> Int {
    let counter = Counter()
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<100 {
            group.addTask { await counter.increment() }
        }
        await group.waitForAll()
    }
    return await counter.currentValue()
}
