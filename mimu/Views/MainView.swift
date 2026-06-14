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



    // Glow visibility — separate from isRecording so the fade-out can finish
    // before the view is removed from the hierarchy.
    @State private var isGlowVisible = false

    // Highlight glow for newly added row
    @State private var latestTaskId: UUID?
    @State private var latestEventId: UUID?
    @State private var highlightOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Tasks Section
                        if !tasks.isEmpty {
                            sectionHeader(title: "Tasks", icon: "checklist")
                            
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
                            sectionHeader(title: "Upcoming Events", icon: "calendar")
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
                .navigationTitle("My List")
                .background(Color(uiColor: .systemGroupedBackground))

                // Siri glow — only in the hierarchy while recording or fading out.
                // Removing it when idle eliminates all GPU blur work at idle.
                if isGlowVisible {
                    SiriGlowView(isActive: speechManager.isRecording)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                }

                // Floating Bottom Pill
                bottomPill
                    .zIndex(2)
            }
            .coordinateSpace(name: "root")
        }
        .onAppear {
            // Delay warmup by 1 s so it doesn't race with the initial layout
            // pass and gesture recognizer setup (fixes gesture gate timeout).
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                speechManager.preparePermissions()
            }
        }
        .onChange(of: speechManager.isRecording) { _, isRecording in
            if isRecording {
                isGlowVisible = true
            } else {
                // Keep alive long enough for the 0.5 s fade-out to complete.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isGlowVisible = false
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
    
    private func taskRow(_ task: AppTask) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    task.isCompleted.toggle()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(.body, design: .rounded))
                .strikethrough(task.isCompleted, color: .secondary)
                .foregroundColor(task.isCompleted ? .secondary : .primary)

            Spacer()

            // Delete button
            Button(action: {
                withAnimation { modelContext.delete(task) }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        .overlay {
            if task.id == latestTaskId {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.40, green: 0.70, blue: 1.00)
                                    .opacity(highlightOpacity),
                                Color(red: 0.60, green: 0.38, blue: 1.00)
                                    .opacity(highlightOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.8
                    )
            }
        }

    }

    private func eventRow(_ event: AppEvent) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 2) {
                    Text(event.date, format: .dateTime.month())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                    Text(event.date, format: .dateTime.day())
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)

                Text(event.date, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Delete button
            Button(action: {
                withAnimation { modelContext.delete(event) }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        .overlay {
            if event.id == latestEventId {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.30, green: 0.60, blue: 1.00)
                                    .opacity(highlightOpacity),
                                Color(red: 0.50, green: 0.35, blue: 1.00)
                                    .opacity(highlightOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.8
                    )
            }
        }

    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No tasks or events yet")
                .font(.title3.bold())
            
            Text("Tap the microphone below and say what you need to get done. Mimu will sort it for you.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
    }
    
    private var bottomPill: some View {
        HStack(spacing: 10) {
            // Left: waveform when recording, mic icon when idle
            Group {
                if speechManager.isRecording {
                    WaveformView(audioLevel: speechManager.audioLevel)
                        .frame(width: 36, height: 28)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    Image(systemName: "mic")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: speechManager.isRecording)

            // Middle: live transcription while recording, placeholder when idle
            Text(speechManager.isRecording && !speechManager.transcribedText.isEmpty
                 ? speechManager.transcribedText
                 : "Say a task or event...")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(speechManager.isRecording && !speechManager.transcribedText.isEmpty ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .animation(.easeInOut(duration: 0.2), value: speechManager.transcribedText)

            // Right: mic to start recording, send button to submit
            Button(action: handleRecordingTap) {
                ZStack {
                    Circle()
                        .fill(speechManager.isRecording ? Color.blue : Color(uiColor: .tertiarySystemFill))
                        .frame(width: 44, height: 44)

                    Image(systemName: speechManager.isRecording ? "arrow.up" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(speechManager.isRecording ? .white : .primary)
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: speechManager.isRecording)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
            // Start recording — glow fires automatically via isRecording binding
            Self.haptic.impactOccurred()
            speechManager.startRecording()
        }
    }
}



#Preview {
    MainView()
        .modelContainer(for: [AppTask.self, AppEvent.self], inMemory: true)
}
