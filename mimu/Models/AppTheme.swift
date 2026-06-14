import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case bubblegum
    case mint
    case lavender
    case honey
    case cloud
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .bubblegum: return "Bubblegum Pink 🌸"
        case .mint: return "Minty Matcha 🍵"
        case .lavender: return "Lavender Dreams 🦄"
        case .honey: return "Sunny Honey 🍯"
        case .cloud: return "Soft Cloud ☁️"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .bubblegum: return Color(red: 0.99, green: 0.94, blue: 0.95)
        case .mint: return Color(red: 0.93, green: 0.97, blue: 0.95)
        case .lavender: return Color(red: 0.96, green: 0.95, blue: 0.99)
        case .honey: return Color(red: 0.99, green: 0.98, blue: 0.91)
        case .cloud: return Color(red: 0.93, green: 0.96, blue: 0.99)
        }
    }
    
    var cardColor: Color {
        return .white
    }
    
    var accentColor: Color {
        switch self {
        case .bubblegum: return Color(red: 0.96, green: 0.51, blue: 0.64)
        case .mint: return Color(red: 0.44, green: 0.74, blue: 0.58)
        case .lavender: return Color(red: 0.65, green: 0.59, blue: 0.88)
        case .honey: return Color(red: 0.96, green: 0.73, blue: 0.32)
        case .cloud: return Color(red: 0.48, green: 0.71, blue: 0.89)
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .bubblegum: return Color(red: 0.98, green: 0.78, blue: 0.83)
        case .mint: return Color(red: 0.75, green: 0.91, blue: 0.82)
        case .lavender: return Color(red: 0.85, green: 0.82, blue: 0.96)
        case .honey: return Color(red: 0.99, green: 0.91, blue: 0.71)
        case .cloud: return Color(red: 0.78, green: 0.88, blue: 0.96)
        }
    }

    var textColor: Color {
        switch self {
        case .bubblegum: return Color(red: 0.35, green: 0.15, blue: 0.20)
        case .mint: return Color(red: 0.15, green: 0.30, blue: 0.22)
        case .lavender: return Color(red: 0.22, green: 0.18, blue: 0.35)
        case .honey: return Color(red: 0.35, green: 0.25, blue: 0.10)
        case .cloud: return Color(red: 0.15, green: 0.25, blue: 0.35)
        }
    }
    
    var textSecondaryColor: Color {
        switch self {
        case .bubblegum: return Color(red: 0.55, green: 0.35, blue: 0.40)
        case .mint: return Color(red: 0.35, green: 0.50, blue: 0.42)
        case .lavender: return Color(red: 0.42, green: 0.38, blue: 0.55)
        case .honey: return Color(red: 0.55, green: 0.45, blue: 0.30)
        case .cloud: return Color(red: 0.35, green: 0.45, blue: 0.55)
        }
    }
}
