import Foundation
import NaturalLanguage

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
        
        // NaturalLanguage framework logic fallback
        if hasEventIntentUsingNLP(textToAnalyze) {
            // Even if we couldn't parse the time, if NL says it's an event...
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
    
    /// Logic-based Natural Language processing to classify intention
    private func hasEventIntentUsingNLP(_ text: String) -> Bool {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var isEvent = false
        
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        
        // Verbs that usually determine an event (meetings, sending, calling at a time)
        let eventIndicators: Set<String> = ["meet", "call", "send", "appointment", "schedule"]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let _ = tag {
                let word = String(text[tokenRange]).lowercased()
                if eventIndicators.contains(word) {
                    isEvent = true
                }
            }
            return !isEvent // stop early if found
        }
        
        return isEvent
    }
}
