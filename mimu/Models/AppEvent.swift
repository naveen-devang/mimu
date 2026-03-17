import Foundation
import SwiftData

@Model
final class AppEvent {
    var id: UUID
    var title: String
    var date: Date
    var createdAt: Date

    init(id: UUID = UUID(), title: String, date: Date, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.date = date
        self.createdAt = createdAt
    }
}
