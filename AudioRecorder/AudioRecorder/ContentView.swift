//
//  ContentView.swift
//  AudioRecorder
//
//  Created by richard Haynes on 9/2/24.
//

import SwiftUI

import AVFoundation



struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()

    var body: some View {
        VStack(spacing: 40) {
            Text("Audio Recorder")
                .font(.largeTitle)
                .padding()

            if audioRecorder.isRecording {
                Button(action: {
                    audioRecorder.stopRecording()
                }) {
                    Text("Stop Recording")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Button(action: {
                    audioRecorder.startRecording()
                }) {
                    Text("Start Recording")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if let recordingURL = audioRecorder.recordingURL {
                Text("Recording saved at:")
                    .font(.subheadline)
                    .padding(.top)
                Text(recordingURL.lastPathComponent)
                    .font(.caption)
            }
            
            Button(action: {
                audioRecorder.startPlayback()
            }) {
                Text("Play Recording")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear{
            audioRecorder.checkMicrophonePermission()
        }
        .padding()
    }
}

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
        private var audioPlayer: AVAudioPlayer?
        @Published var isRecording = false
        @Published var isPlaying = false
        @Published var recordingURL: URL?
    
    private func setUpAudio() {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try audioSession.setActive(true)
            } catch {
                print("Audio Session setup error: \(error.localizedDescription)")
            }
        }
    
    func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            print("Microphone access granted.")
        case .denied:
            print("Microphone access denied.")
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("Microphone access granted.")
                } else {
                    print("Microphone access denied.")
                }
            }
        @unknown default:
            print("Unknown microphone permission status.")
        }
    }

    func startRecording() {
        setUpAudio()
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingURL = nil
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingURL = audioRecorder?.url
    }
    func startPlayback() {
            guard let recordingURL = recordingURL else { return }

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
                //audioPlayer?.delegate = self
                audioPlayer?.play()
                isPlaying = true
            } catch {
                print("Failed to start playback: \(error.localizedDescription)")
            }
        }

        func stopPlayback() {
            audioPlayer?.stop()
            isPlaying = false
        }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
        } else {
            print("Recording failed.")
        }
    }
}

#Preview {
    ContentView()
}

