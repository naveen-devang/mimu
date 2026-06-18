import SwiftUI
import SwiftData
import UIKit

struct MainView: View {
    // Cached haptic generator — avoids re-creating the Taptic Engine link on every tap.
    private static let haptic = UIImpactFeedbackGenerator(style: .medium)
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppTask.createdAt, order: .reverse) private var tasks: [AppTask]
    @Query(sort: \AppEvent.createdAt, order: .reverse) private var events: [AppEvent]
    
    @State private var speechManager = SpeechManager()
    @State private var mimuEngine = MimuEngine()
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .bubblegum
    @State private var isSettingsPresented = false

    // Highlight glow for newly added row
    @State private var latestTaskId: UUID?
    @State private var latestEventId: UUID?
    @State private var highlightOpacity: Double = 0
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background color matching current pastel theme
                selectedTheme.backgroundColor
                    .ignoresSafeArea()

                // Main content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Cute Custom Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello, Sweet Friend! ✨")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedTheme.textSecondaryColor)
                                Text("My Cozy List")
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundColor(selectedTheme.textColor)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                isSettingsPresented = true
                                Self.haptic.impactOccurred()
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(selectedTheme.accentColor)
                                    .padding(12)
                                    .background(selectedTheme.cardColor)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedTheme.secondaryColor.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 12)
                        
                        // Tasks Section
                        if !tasks.isEmpty {
                            sectionHeader(title: "Tasks", icon: "checkmark.bubble.fill")
                            
                            VStack(spacing: 12) {
                                ForEach(tasks) { task in
                                    taskRow(task)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.88, anchor: .top)
                                                .combined(with: .opacity),
                                            removal: .opacity.combined(with: .scale(scale: 0.92))
                                        ))
                                }
                            }
                        }
                        
                        // Events Section
                        if !events.isEmpty {
                            sectionHeader(title: "Upcoming Events", icon: "calendar.badge.clock")
                                .padding(.top, tasks.isEmpty ? 0 : 16)
                            
                            VStack(spacing: 12) {
                                ForEach(events) { event in
                                    eventRow(event)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.88, anchor: .top)
                                                .combined(with: .opacity),
                                            removal: .opacity.combined(with: .scale(scale: 0.92))
                                        ))
                                }
                            }
                        }
                        
                        // Empty state if nothing exists
                        if tasks.isEmpty && events.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding()
                    .padding(.bottom, 120) // Extra padding for the floating pill
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    scrollOffset = newValue
                }
            }
            .coordinateSpace(name: "root")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .overlay(alignment: .top) {
                progressiveTopBlur
            }
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    progressiveBottomBlur
                    bottomPill
                }
            }
        }
        .onAppear {
            // Delay warmup by 1 s so it doesn't race with the initial layout
            // pass and gesture recognizer setup (fixes gesture gate timeout).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                speechManager.preparePermissions()
                NotificationManager.shared.requestAuthorization()
            }
        }

    }
    
    // MARK: - Subviews
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(selectedTheme.accentColor)
                .font(.system(size: 16, weight: .bold))
            Text(title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(selectedTheme.textColor)
        }
        .padding(.horizontal, 6)
    }
    
    private func taskRow(_ task: AppTask) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    task.isCompleted.toggle()
                }
                Self.haptic.impactOccurred()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(task.isCompleted ? selectedTheme.accentColor : selectedTheme.textColor.opacity(0.3))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .strikethrough(task.isCompleted, color: selectedTheme.textColor.opacity(0.4))
                .foregroundColor(task.isCompleted ? selectedTheme.textColor.opacity(0.5) : selectedTheme.textColor)

            Spacer()

            // Delete button
            Button(action: {
                withAnimation { modelContext.delete(task) }
                Self.haptic.impactOccurred()
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(selectedTheme.accentColor.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(selectedTheme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(selectedTheme.secondaryColor.opacity(0.2), lineWidth: 1.5)
        )
        .overlay {
            if task.id == latestTaskId {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                selectedTheme.accentColor.opacity(highlightOpacity),
                                selectedTheme.secondaryColor.opacity(highlightOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
            }
        }
    }

    private func eventRow(_ event: AppEvent) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(selectedTheme.accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(spacing: 2) {
                    Text(event.date, format: .dateTime.month())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(selectedTheme.accentColor)
                        .textCase(.uppercase)
                    Text(event.date, format: .dateTime.day())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(selectedTheme.accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(selectedTheme.textColor)

                Text(event.date, style: .time)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondaryColor)
            }

            Spacer()

            // Delete button
            Button(action: {
                NotificationManager.shared.cancelNotification(for: event)
                withAnimation { modelContext.delete(event) }
                Self.haptic.impactOccurred()
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(selectedTheme.accentColor.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(selectedTheme.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(selectedTheme.secondaryColor.opacity(0.2), lineWidth: 1.5)
        )
        .overlay {
            if event.id == latestEventId {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                selectedTheme.accentColor.opacity(highlightOpacity),
                                selectedTheme.secondaryColor.opacity(highlightOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(selectedTheme.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(selectedTheme.accentColor)
            }
            
            Text("Your List is Empty ✨")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(selectedTheme.textColor)
            
            Text("Tap the mic below and speak your goals! Mimu will automatically categorize your tasks & events. 🌸")
                .font(.system(.body, design: .rounded))
                .foregroundColor(selectedTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(4)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
    
    private var bottomPill: some View {
        HStack(spacing: 12) {
            // Left: waveform when recording, mic icon when idle
            Group {
                if speechManager.isRecording {
                    WaveformView(audioLevel: speechManager.audioLevel)
                        .frame(width: 36, height: 28)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(selectedTheme.accentColor)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: speechManager.isRecording)

            // Middle: live transcription while recording, placeholder when idle
            Text(speechManager.isRecording && !speechManager.transcribedText.isEmpty
                 ? speechManager.transcribedText
                 : "Speak a task or event...")
                .font(.system(size: 15, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(speechManager.isRecording && !speechManager.transcribedText.isEmpty ? selectedTheme.textColor : selectedTheme.textSecondaryColor.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .animation(.easeInOut(duration: 0.2), value: speechManager.transcribedText)

            // Right: mic to start recording, send button to submit
            Button(action: handleRecordingTap) {
                ZStack {
                    Circle()
                        .fill(speechManager.isRecording ? selectedTheme.accentColor : selectedTheme.secondaryColor.opacity(0.4))
                        .frame(width: 44, height: 44)

                    Image(systemName: speechManager.isRecording ? "arrow.up" : "mic.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(speechManager.isRecording ? .white : selectedTheme.textColor)
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: speechManager.isRecording)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(selectedTheme.cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(selectedTheme.accentColor.opacity(0.25), lineWidth: 2)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func handleRecordingTap() {
        if speechManager.isRecording {
            // Stop recording — glow fades out automatically via isRecording binding
            speechManager.stopRecording()
            let captured = speechManager.transcribedText
            speechManager.transcribedText = ""
            guard !captured.trimmingCharacters(in: .whitespaces).isEmpty else { return }

            // Parse and insert immediately
            let intent = mimuEngine.parseIntent(from: captured)
            Self.haptic.impactOccurred()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                switch intent {
                case .task(let title):
                    let task = AppTask(title: title)
                    modelContext.insert(task)
                    latestTaskId = task.id
                case .event(let title, let date):
                    let event = AppEvent(title: title, date: date)
                    modelContext.insert(event)
                    NotificationManager.shared.scheduleNotification(for: event)
                    latestEventId = event.id
                }
            }

            // Row highlight flash
            withAnimation(.easeOut(duration: 0.35)) { highlightOpacity = 1.0 }
            withAnimation(.easeOut(duration: 1.2).delay(0.35)) { highlightOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                latestTaskId = nil
                latestEventId = nil
            }

        } else {
            // Start recording
            Self.haptic.impactOccurred()
            speechManager.startRecording()
        }
    }
    
    // MARK: - Progressive Top Blur Helpers
    
    private var topBlurOpacity: Double {
        let threshold: CGFloat = 30
        return Double(min(max(scrollOffset, 0) / threshold, 1.0))
    }
    
    private var progressiveTopBlur: some View {
        VariableBlurView(maxBlurRadius: 15, direction: .blurredTopClearBottom, startOffset: 0.15)
            .frame(height: 110) // Covers safe area + provides a wide, gradual fade zone
            .overlay {
                // A very subtle glassy sheen that fades out completely at the bottom of the blur.
                // Uses a constant white color for the best pastel match under any OS mode.
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.35),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .top)
            .opacity(topBlurOpacity)
            .allowsHitTesting(false) // Let touches pass through
    }
    
    private var progressiveBottomBlur: some View {
        VariableBlurView(maxBlurRadius: 15, direction: .blurredBottomClearTop, startOffset: 0.15)
            .frame(height: 140) // Covers safe area + floating pill + gradual fade zone
            .overlay {
                // Subtle glassy sheen that fades out completely at the top of the blur.
                // Uses a constant white color for the best pastel match under any OS mode.
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false) // Let touches pass through
    }
}



#Preview {
    MainView()
        .modelContainer(for: [AppTask.self, AppEvent.self], inMemory: true)
}
