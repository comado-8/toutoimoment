import CoreGraphics
import Foundation

enum WatchingMotionCoordinateSpace {
    static let name = "watching-mode.motion"
}

struct ReactionFlightEvent: Identifiable, Equatable {
    let id: UUID
    let emoji: String
    let origin: CGPoint
    let startedAt: Date
    let lane: Int
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        emoji: String,
        origin: CGPoint,
        startedAt: Date,
        lane: Int,
        duration: TimeInterval
    ) {
        self.id = id
        self.emoji = emoji
        self.origin = origin
        self.startedAt = startedAt
        self.lane = lane
        self.duration = duration
    }
}

struct ReactionFlightQueue: Equatable {
    static let maximumActiveCount = 18

    private(set) var events: [ReactionFlightEvent] = []
    private(set) var nextSequence = 0

    @discardableResult
    mutating func enqueue(
        emoji: String,
        origin: CGPoint,
        at date: Date = Date(),
        reducesMotion: Bool
    ) -> ReactionFlightEvent {
        let lane = nextSequence % ReactionFlightPath.paths.count
        let duration = reducesMotion
            ? ReactionFlightPath.reducedMotionDuration
            : ReactionFlightPath.paths[lane].duration
        nextSequence += 1

        let event = ReactionFlightEvent(
            emoji: emoji,
            origin: origin,
            startedAt: date,
            lane: lane,
            duration: duration
        )
        events.append(event)
        if events.count > Self.maximumActiveCount {
            events.removeFirst(events.count - Self.maximumActiveCount)
        }
        return event
    }

    mutating func remove(id: ReactionFlightEvent.ID) {
        events.removeAll { $0.id == id }
    }
}

struct ReactionFlightPath: Equatable {
    static let reducedMotionDuration: TimeInterval = 0.35
    static let paths: [ReactionFlightPath] = [
        .init(rise: 280, drift: -34, sway: 12, duration: 1.52),
        .init(rise: 304, drift: 24, sway: 15, duration: 1.64),
        .init(rise: 292, drift: -10, sway: 18, duration: 1.58),
        .init(rise: 320, drift: 38, sway: 11, duration: 1.70),
        .init(rise: 268, drift: -24, sway: 16, duration: 1.48),
        .init(rise: 310, drift: 8, sway: 13, duration: 1.66),
    ]

    let rise: CGFloat
    let drift: CGFloat
    let sway: CGFloat
    let duration: TimeInterval
}
