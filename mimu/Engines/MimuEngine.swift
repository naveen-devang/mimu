import Foundation

enum ParsedIntent {
    case task(title: String)
    case event(title: String, date: Date)
}

final class MimuEngine {
    
    /// Cached date detector — NSDataDetector is thread-safe and reusable.
    private let dateDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }()
    
    /// Parses the transcribed text and returns either a AppTask or AppEvent structure intent
    func parseIntent(from text: String) -> ParsedIntent {
        let textToAnalyze = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if textToAnalyze.isEmpty {
            return .task(title: "Empty Task")
        }
        
        // If a valid date/time is extracted, we classify it as an Event.
        if let eventDate = extractDate(from: textToAnalyze) {
            return .event(title: textToAnalyze, date: eventDate)
        }
        
        // High-performance word boundary keyword check
        if hasEventIntent(textToAnalyze) {
            // Even if we couldn't parse the time, if keywords say it's an event...
            return .event(title: textToAnalyze, date: Date().addingTimeInterval(3600)) // fallback +1 hr
        }
        
        return .task(title: textToAnalyze)
    }
    
    /// Use the cached NSDataDetector for robust extraction of dates and time
    private func extractDate(from text: String) -> Date? {
        guard let detector = dateDetector else { return nil }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches {
            if let date = match.date {
                return date // Return the first detected valid date/time
            }
        }
        return nil
    }
    
    /// High-performance keyword check to classify intention.
    /// Replaces NLTagger to prevent heavy framework loading and main thread hangs.
    private func hasEventIntent(_ text: String) -> Bool {
        // Words indicating calendar/event intent
        let eventIndicators: Set<String> = ["meet", "meeting", "call", "send", "appointment", "schedule", "scheduled"]
        
        // Tokenize using simple word boundaries (alphanumerics only)
        let words = text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        for word in words {
            if eventIndicators.contains(word) {
                return true
            }
        }
        
        return false
    }
}
