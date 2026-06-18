import Foundation
import Speech
import AVFoundation
import Accelerate

@Observable
final class SpeechManager {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    /// Tracks whether a tap is currently installed on the input node,
    /// so tearDown() never calls removeTap when none exists (which crashes).
    private var tapInstalled = false
    /// Frame counter for throttling audio level updates to ~15 Hz.
    private var audioFrameCounter: Int = 0

    var transcribedText: String = ""
    var isRecording: Bool = false
    var audioLevel: Float = 0
    var isAuthorized: Bool = false

    init() { }

    // MARK: - Permissions & Warm-up

    /// Call from MainView.onAppear. Requests permissions and pre-warms the
    /// audio hardware so every subsequent mic tap is instant.
    func preparePermissions() {
        // Speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = status == .authorized
            }
        }
        // Microphone permission (separate OS gate from speech)
        AVAudioApplication.requestRecordPermission { _ in }

        // Pre-warm the audio engine off-main to prevent startup hangs.
        warmUpEngine()
    }

    /// Touches the inputNode (forces iOS audio hardware I/O init) and calls
    /// prepare() (allocates DSP buffers) on a background thread.
    private func warmUpEngine() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard !self.audioEngine.isRunning else { return }
            let _ = self.audioEngine.inputNode   // ~300 ms hardware init, only first call
            self.audioEngine.prepare()           // ~300 ms DSP buffer allocation
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard isAuthorized else {
            // Permissions not yet granted — request and retry once resolved.
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.isAuthorized = true
                        self?.startRecording()
                    }
                }
            }
            return
        }

        // Clean up any previous session before starting a fresh one.
        tearDown()

        // Set recording flag IMMEDIATELY so the glow animation starts
        // without waiting for the audio session (which blocks ~200-500 ms).
        isRecording = true
        transcribedText = ""

        // Heavy audio session setup on a background queue to avoid
        // blocking the gesture system ("gesture gate timed out").
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Audio session error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.tearDown() }
                return
            }

            // Hop back to main for AVAudioEngine (not thread-safe).
            DispatchQueue.main.async {
                self.finishStartRecording()
            }
        }
    }

    /// Completes recording setup on the main thread after the audio session
    /// has been configured in the background.
    private func finishStartRecording() {
        guard isRecording else { return }   // tearDown() may have been called

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.transcribedText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.tearDown()
            }
        }

        // inputNode.outputFormat(forBus:) can return a zero-sampleRate / zero-channel
        // format if the audio session hasn't fully activated the hardware yet (common
        // in the Simulator and on first cold-start). Passing that invalid format to
        // installTap throws kAudioUnitErr_InvalidFormat (error 561015905) and crashes.
        // We validate here and fall back to a known-good format.
        let rawFormat = inputNode.outputFormat(forBus: 0)
        let tapFormat: AVAudioFormat
        if rawFormat.sampleRate > 0 && rawFormat.channelCount > 0 {
            tapFormat = rawFormat
        } else {
            // Safe default: 44.1 kHz mono — Speech framework and AudioUnit both accept this.
            guard let fallback = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else {
                print("SpeechManager: Could not create fallback audio format — aborting.")
                tearDown()
                return
            }
            tapFormat = fallback
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Throttle UI updates to every 3rd callback (~15 Hz instead of ~44 Hz).
            guard let self else { return }
            self.audioFrameCounter += 1
            guard self.audioFrameCounter % 3 == 0 else { return }

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            // vDSP SIMD-vectorised RMS — guaranteed fast on Apple Silicon.
            var meanSquare: Float = 0
            vDSP_measqv(channelData, 1, &meanSquare, vDSP_Length(count))
            let level = min(sqrt(meanSquare) * 12, 1.0)
            DispatchQueue.main.async { self.audioLevel = level }
        }
        tapInstalled = true

        // prepare() is a no-op if already prepared by warmUpEngine() — fast path.
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error.localizedDescription)")
            tearDown()
        }
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        tearDown()
    }

    // MARK: - Teardown

    private func tearDown() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        // Only remove the tap if we know one is installed — avoids an exception.
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        audioLevel = 0
        audioFrameCounter = 0

        // Deactivate the audio session so the mic hardware powers down
        // and the recording indicator disappears from the status bar.
        DispatchQueue.global(qos: .utility).async {
            try? AVAudioSession.sharedInstance().setActive(
                false, options: .notifyOthersOnDeactivation
            )
        }
    }
}
