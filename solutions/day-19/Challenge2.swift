// Worked solution: Read a small imported text file safely
// The loop handles partial reads while never accumulating more than the limit plus one byte. It avoids assuming that a file-size metadata check remains true until reading completes. Perform file I/O through an appropriate service away from time-critical UI work; copy accepted content into your repository if it should persist.
// Read lessons/day-19.md for any surrounding types or setup.

import Foundation

enum ImportError: Error {
    case tooLarge
    case invalidText
}

func importNotes(from url: URL) throws -> String {
    let scoped = url.startAccessingSecurityScopedResource()
    defer {
        if scoped { url.stopAccessingSecurityScopedResource() }
    }

    let file = try FileHandle(forReadingFrom: url)
    defer { try? file.close() }

    let limit = 64 * 1024
    var data = Data()
    while data.count <= limit {
        let remaining = limit + 1 - data.count
        guard let chunk = try file.read(upToCount: remaining),
              !chunk.isEmpty else { break }
        data.append(chunk)
    }

    guard data.count <= limit else { throw ImportError.tooLarge }
    guard let text = String(data: data, encoding: .utf8) else {
        throw ImportError.invalidText
    }
    return text
}
