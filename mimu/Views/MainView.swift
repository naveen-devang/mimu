import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppTask.createdAt, order: .reverse) private var tasks: [AppTask]
    @Query(sort: \AppEvent.createdAt, order: .reverse) private var events: [AppEvent]
    
    @State private var speechManager = SpeechManager()
    @State private var mimuEngine = MimuEngine()

    @State private var showParticles: Bool = false
    @State private var pillLaunching: Bool = false   // text-to-particles launch state
    @State private var animatedText: String = ""

    // Deferred insertion — stored until particles finish
    @State private var pendingTaskTitle: String?
    @State private var pendingEventTitle: String?
    @State private var pendingEventDate: Date?

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

                // Floating Bottom Pill
                bottomPill

                // Apple Pay beam animation — sits on top of everything
                if showParticles {
                    ApplePayBeamView(text: animatedText) {
                        pillLaunching = false   // restore pill to normal state
                        // Insert the item now so it animates in after particles clear
                        if let title = pendingTaskTitle {
                            let task = AppTask(title: title)
                            withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) {
                                modelContext.insert(task)
                            }
                            latestTaskId = task.id
                            pendingTaskTitle = nil
                        } else if let title = pendingEventTitle, let date = pendingEventDate {
                            let event = AppEvent(title: title, date: date)
                            withAnimation(.spring(response: 0.52, dampingFraction: 0.76)) {
                                modelContext.insert(event)
                            }
                            latestEventId = event.id
                            pendingEventTitle = nil
                            pendingEventDate = nil
                        }
                        showParticles = false
                        // Glow highlight on the new row
                        withAnimation(.easeOut(duration: 0.35)) { highlightOpacity = 1.0 }
                        withAnimation(.easeOut(duration: 1.2).delay(0.35)) { highlightOpacity = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            latestTaskId = nil
                            latestEventId = nil
                        }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.40, green: 0.70, blue: 1.00)
                                .opacity(task.id == latestTaskId ? highlightOpacity : 0),
                            Color(red: 0.60, green: 0.38, blue: 1.00)
                                .opacity(task.id == latestTaskId ? highlightOpacity : 0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(task) }
            } label: {
                Label("Delete", systemImage: "trash")
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
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.30, green: 0.60, blue: 1.00)
                                .opacity(event.id == latestEventId ? highlightOpacity : 0),
                            Color(red: 0.50, green: 0.35, blue: 1.00)
                                .opacity(event.id == latestEventId ? highlightOpacity : 0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(event) }
            } label: {
                Label("Delete", systemImage: "trash")
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
                // Text compresses toward the send button and dissolves as particles launch
                .scaleEffect(pillLaunching ? 0.01 : 1.0, anchor: .trailing)
                .offset(x: pillLaunching ? 40 : 0, y: pillLaunching ? -8 : 0)
                .opacity(pillLaunching ? 0 : 1.0)
                .animation(.easeIn(duration: 0.14), value: pillLaunching)

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
                .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 12)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }



    // MARK: - Actions

    private func handleRecordingTap() {
        if speechManager.isRecording {
            speechManager.stopRecording()
            let captured = speechManager.transcribedText
            guard !captured.trimmingCharacters(in: .whitespaces).isEmpty else { return }

            // ── Store intent — insertion deferred until particles finish ──
            let intent = mimuEngine.parseIntent(from: captured)
            switch intent {
            case .task(let title):
                pendingTaskTitle  = title
                pendingEventTitle = nil
                pendingEventDate  = nil
            case .event(let title, let date):
                pendingTaskTitle  = nil
                pendingEventTitle = title
                pendingEventDate  = date
            }

            // ── Text-to-particles: collapse pill text first ──
            animatedText = captured
            pillLaunching = true
            speechManager.transcribedText = ""

            // ── Haptics ──
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            // ── Fire particle animation after text collapse ──
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                showParticles = true
            }

        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            speechManager.startRecording()
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [AppTask.self, AppEvent.self], inMemory: true)
}
