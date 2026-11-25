//
//  VolumeBar.swift
//  Crema
//
//  A slim system-volume control for the top right of the expanded notch.
//

import CoreAudio
import SwiftUI

/// Reads and sets the default output device's volume with CoreAudio.
@MainActor
final class SystemVolume: ObservableObject {
    static let shared = SystemVolume()

    @Published private(set) var level: Float = 0.5
    @Published private(set) var isMuted = false

    private var deviceID = AudioObjectID(kAudioObjectUnknown)
    private var listenerBlock: AudioObjectPropertyListenerBlock?

    // 'vmvc' (virtual main volume) works on devices that only expose per-channel controls.
    private let virtualMainVolume: AudioObjectPropertySelector = 0x766D_7663

    private init() {
        refresh()
        installListeners()
    }

    private func address(_ selector: AudioObjectPropertySelector,
                         scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    private func defaultOutputDevice() -> AudioObjectID {
        var id = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var addr = address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &id)
        return id
    }

    func refresh() {
        deviceID = defaultOutputDevice()
        guard deviceID != kAudioObjectUnknown else { return }

        var volume = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        var vAddr = address(virtualMainVolume)
        if AudioObjectGetPropertyData(deviceID, &vAddr, 0, nil, &size, &volume) == noErr {
            level = Float(min(max(volume, 0), 1))
        }

        var muted = UInt32(0)
        var mSize = UInt32(MemoryLayout<UInt32>.size)
        var mAddr = address(kAudioDevicePropertyMute)
        if AudioObjectGetPropertyData(deviceID, &mAddr, 0, nil, &mSize, &muted) == noErr {
            isMuted = muted != 0
        }
    }

    func setLevel(_ newLevel: Float) {
        guard deviceID != kAudioObjectUnknown else { return }
        var value = Float32(min(max(newLevel, 0), 1))
        var addr = address(virtualMainVolume)
        AudioObjectSetPropertyData(deviceID, &addr, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
        level = Float(value)
        if value > 0, isMuted { setMuted(false) }
    }

    func toggleMute() { setMuted(!isMuted) }

    private func setMuted(_ muted: Bool) {
        guard deviceID != kAudioObjectUnknown else { return }
        var value = UInt32(muted ? 1 : 0)
        var addr = address(kAudioDevicePropertyMute)
        if AudioObjectSetPropertyData(deviceID, &addr, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value) == noErr {
            isMuted = muted
        }
    }

    /// Keeps the bar in step when volume changes elsewhere or the output device switches.
    private func installListeners() {
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
        listenerBlock = block
        var deviceAddr = address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &deviceAddr, .main, block)
        if deviceID != kAudioObjectUnknown {
            var vAddr = address(virtualMainVolume)
            AudioObjectAddPropertyListenerBlock(deviceID, &vAddr, .main, block)
            var mAddr = address(kAudioDevicePropertyMute)
            AudioObjectAddPropertyListenerBlock(deviceID, &mAddr, .main, block)
        }
    }
}

struct VolumeBar: View {
    @ObservedObject private var volume = SystemVolume.shared
    @State private var dragging = false

    private var icon: String {
        if volume.isMuted || volume.level == 0 { return "speaker.slash.fill" }
        if volume.level < 0.33 { return "speaker.wave.1.fill" }
        if volume.level < 0.66 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: { volume.toggleMute() }) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(PlainButtonStyle())

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.18))
                    Capsule()
                        .fill(Color.white.opacity(volume.isMuted ? 0.35 : 0.9))
                        .frame(width: max(4, geo.size.width * CGFloat(volume.level)))
                }
                .frame(height: dragging ? 8 : 5)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragging = true
                            volume.setLevel(Float(value.location.x / geo.size.width))
                        }
                        .onEnded { _ in dragging = false }
                )
                .animation(.smooth(duration: 0.15), value: dragging)
            }
            .frame(width: 70, height: 24)
        }
        .onAppear { volume.refresh() }
    }
}

#Preview {
    VolumeBar().padding().background(.black)
}
