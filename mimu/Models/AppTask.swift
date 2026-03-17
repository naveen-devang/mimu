import Foundation
import SwiftData

@Model
final class AppTask {
    var id: UUID
    var title: String
    var createdAt: Date
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }
}
