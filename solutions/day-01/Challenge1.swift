// Worked solution: Find the urgent unfinished task
// first(where:) communicates that you want one existing element. The optional lets the caller display a useful empty state rather than accidentally treating fabricated data as real.
// Read lessons/day-01.md for any surrounding types or setup.

func firstUrgent(in tasks: [TaskItem]) -> TaskItem? {
    tasks.first { $0.priority == .high && !$0.isComplete }
}
