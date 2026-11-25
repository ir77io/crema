//
//  NotchBanner.swift
//  Crema
//
//  Compact pop-outs for Crema's own events (song changes, upcoming calendar events).
//  A small pill drops out of the closed notch, then retracts back into it.
//

import Defaults
import SwiftUI

struct NotchBanner: Equatable, Identifiable {
    let id = UUID()
    var symbol: String? = nil
    var image: NSImage? = nil
    var title: String
    var subtitle: String
}

struct NotchBannerCard: View {
    let banner: NotchBanner

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let image = banner.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: banner.symbol ?? "bell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CremaPalette.cremaSurface)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(CremaPalette.espresso)
                }
            }
            .frame(width: 30, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(banner.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(banner.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: 190, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                removal: .opacity))
    }
}

/// Watches the calendar and pops out a banner shortly before an event starts.
@MainActor
final class UpcomingEventNotifier {
    static let shared = UpcomingEventNotifier()

    /// How far ahead of the start time to announce.
    private let leadTime: TimeInterval = 5 * 60
    private var announced: Set<String> = []
    private var task: Task<Void, Never>?

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.check()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private func check() async {
        guard Defaults[.showEventBanners], CalendarManager.shared.calendarAuthorizationStatus == .fullAccess else { return }
        let events = await CalendarManager.shared.eventsStarting(within: leadTime)
        let now = Date()
        for event in events {
            let key = "\(event.id)-\(event.start.timeIntervalSince1970)"
            guard !announced.contains(key) else { continue }
            announced.insert(key)

            let minutes = Int((event.start.timeIntervalSince(now) / 60).rounded(.up))
            let subtitle = minutes <= 0 ? "Starting now" : "Starts in \(minutes) min"
            CremaViewCoordinator.shared.showBanner(
                NotchBanner(symbol: "calendar", title: event.title, subtitle: subtitle), duration: 5)
        }
    }
}
