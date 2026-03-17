import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechManager {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

        var transcribedText: String = ""
        var isRecording: Bool = false
        var audioLevel: Float = 0
        var isAuthorized: Bool = false

    init() {
        requestAuthorization()
    }

    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.isAuthorized = authStatus == .authorized
            }
        }
    }

    func startRecording() {
        guard isAuthorized else { return }

        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
            self?.recognitionRequest?.append(buffer)

            // Compute RMS power from the audio buffer
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            var rms: Float = 0
            for i in 0..<frameCount {
                rms += channelData[i] * channelData[i]
            }
            rms = sqrt(rms / Float(frameCount))

            // Map RMS (typically 0.0–0.1+) to a 0.0–1.0 normalized range
            let normalized = min(rms * 12, 1.0)

            DispatchQueue.main.async {
                self?.audioLevel = normalized
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            transcribedText = ""
        } catch {
            print("Audio engine start error: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecording = false
        }
    }
}
