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
    /// Accepts formats:
    ///   TicketNumber,Name[,SponsorLevel]
    /// First row is treated as a header and skipped if its first column isn't a number.
    static func parseCSV(_ text: String) -> [Int: GuestInfo] {
        var result: [Int: GuestInfo] = [:]
        let lines = text.components(separatedBy: .newlines)

        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let columns = parseCSVLine(trimmed)
            guard columns.count >= 2 else { continue }

            guard let ticketID = Int(columns[0].trimmingCharacters(in: .whitespaces)) else {
                // Non-numeric first column → skip (header row or bad data)
                if lineIndex == 0 { continue }
                continue
            }

            let name = columns[1].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }

            let sponsorLevel = columns.count >= 3 ? columns[2].trimmingCharacters(in: .whitespaces) : nil
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
