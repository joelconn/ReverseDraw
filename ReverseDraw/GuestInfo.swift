import Foundation

struct GuestInfo: Codable, Equatable {
    let name: String
    let sponsorLevel: String?

    init(name: String, sponsorLevel: String? = nil) {
        self.name = name
        self.sponsorLevel = sponsorLevel.flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
    }
}

// MARK: - CSV parsing

extension GuestInfo {
    /// Parses CSV lines into a ticket-number keyed dictionary.
    /// Accepts format: Paddle#,FirstName,LastName[,SponsorLevel]
    /// where Paddle# is the ticket number. First row is treated as a header
    /// and skipped if its first column isn't a number.
    static func parseCSV(_ text: String) -> [Int: GuestInfo] {
        var result: [Int: GuestInfo] = [:]
        let lines = text.components(separatedBy: .newlines)
        var paddleNumber = 0

        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let columns = parseCSVLine(trimmed)
            guard columns.count >= 3 else { continue }

            let firstCol = columns[0].trimmingCharacters(in: .whitespaces)

            // Skip header row (first column is "Paddle #" or non-numeric)
            if lineIndex == 0 || firstCol.lowercased() == "paddle #" { continue }

            // Try to parse paddle # from first column; if empty, use row position
            let ticketID: Int
            if let parsed = Int(firstCol), parsed > 0 {
                ticketID = parsed
            } else {
                paddleNumber += 1
                ticketID = paddleNumber
            }

            let firstName = columns[1].trimmingCharacters(in: .whitespaces)
            let lastName = columns[2].trimmingCharacters(in: .whitespaces)
            let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }

            let sponsorLevel = columns.count >= 4 ? columns[3].trimmingCharacters(in: .whitespaces) : nil
            result[ticketID] = GuestInfo(name: name, sponsorLevel: sponsorLevel)
        }

        return result
    }

    // Handles quoted fields with commas inside
    private static func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        columns.append(current)
        return columns
    }
}
