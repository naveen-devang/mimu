import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .bubblegum
    
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
        }
    }
}

#Preview {
    SettingsView()
}
