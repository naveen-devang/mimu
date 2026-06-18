import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .bubblegum
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            ZStack {
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme Style")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(selectedTheme.textColor)
                            
                            Text("Choose a pastel theme to personalize your dashboard. Sweet, cozy, and light! 🌈")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondaryColor)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 4)
                        
                        // Theme List
                        VStack(spacing: 16) {
                            ForEach(AppTheme.allCases) { theme in
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedTheme = theme
                                    }
                                    // Soft feedback
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    HStack(spacing: 16) {
                                        // Colored previews
                                        HStack(spacing: -6) {
                                            Circle()
                                                .fill(theme.accentColor)
                                                .frame(width: 20, height: 20)
                                            Circle()
                                                .fill(theme.secondaryColor)
                                                .frame(width: 20, height: 20)
                                            Circle()
                                                .fill(theme.backgroundColor)
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                        .frame(width: 46)
                                        
                                        Text(theme.name)
                                            .font(.system(.body, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundColor(theme.textColor)
                                        
                                        Spacer()
                                        
                                        if selectedTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(theme.accentColor)
                                                .font(.system(size: 22))
                                        } else {
                                            Circle()
                                                .strokeBorder(theme.textSecondaryColor.opacity(0.3), lineWidth: 2)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(theme.cardColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(selectedTheme == theme ? theme.accentColor : Color.clear, lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Notifications section header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications Settings")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(selectedTheme.textColor)
                            
                            Text("Manage alerts for tasks and events scheduled at a specific time. ⏰")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondaryColor)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 16)
                        
                        // Notifications Status Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(selectedTheme.accentColor.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(selectedTheme.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Event Reminders")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedTheme.textColor)
                                    
                                    Text(notificationStatusText)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondaryColor)
                                }
                                
                                Spacer()
                                
                                if authorizationStatus == .authorized || authorizationStatus == .provisional {
                                    Text("Active ✨")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedTheme.accentColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedTheme.accentColor.opacity(0.1))
                                        .clipShape(Capsule())
                                } else {
                                    Button(action: handleNotificationSettingsTap) {
                                        Text(authorizationStatus == .denied ? "Fix in Settings ⚙️" : "Enable Alerts 🔔")
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedTheme.accentColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20)
                        .background(selectedTheme.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(selectedTheme.secondaryColor.opacity(0.2), lineWidth: 1.5)
                        )
                        
                        // Small footer info
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("Mimu • Crafted with Love 💖")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondaryColor.opacity(0.8))
                                Text("Version 1.0.0")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondaryColor.opacity(0.6))
                            }
                            Spacer()
                        }
                        .padding(.top, 32)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings ⚙️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(selectedTheme.accentColor)
                }
            }
            .onAppear {
                refreshNotificationStatus()
            }
        }
    }
    
    // MARK: - Notifications Helpers
    
    private var notificationStatusText: String {
        switch authorizationStatus {
        case .authorized, .provisional:
            return "You will receive alerts at the event time."
        case .denied:
            return "Alerts are blocked in system settings."
        case .notDetermined:
            return "Tap to authorize cozy reminders."
        case .ephemeral:
            return "Temporary alerts are active."
        @unknown default:
            return "Unknown permission state."
        }
    }
    
    private func refreshNotificationStatus() {
        NotificationManager.shared.getAuthorizationStatus { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
    }
    
    private func handleNotificationSettingsTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if authorizationStatus == .denied {
            // Open system settings page
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        } else {
            NotificationManager.shared.requestAuthorization { granted in
                self.refreshNotificationStatus()
            }
        }
    }
}

#Preview {
    SettingsView()
}
