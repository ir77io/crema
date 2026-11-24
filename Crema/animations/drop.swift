//
//  drop.swift
//  Crema
//
//  Created by Harsh Vardhan  Goswami  on  04/08/24.
//

import Foundation
import SwiftUI


public class CremaAnimations {
    @Published var notchStyle: Style = .notch
    
    init() {
        self.notchStyle = .notch
    }
    
    var animation: Animation {
        if #available(macOS 14.0, *), notchStyle == .notch {
            Animation.spring(.bouncy(duration: 0.4))
        } else {
            Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
        }
    }
    
    // TODO: Move the remaining animations to CremaMotion below

}

/// Crema brand colors shared by the launch animation and the closed-notch rim.
enum CremaPalette {
    static let espresso = Color(red: 0.227, green: 0.114, blue: 0.059)
    static let crema = Color(red: 0.84, green: 0.60, blue: 0.31)
    static let cremaSurface = Color(red: 0.94, green: 0.81, blue: 0.61)
    static var rim: LinearGradient {
        LinearGradient(colors: [cremaSurface, crema], startPoint: .top, endPoint: .bottom)
    }
}

/// Named motion presets for the notch. One preset per role, so the shape,
/// the content and the hover feedback stay in step with each other.
enum CremaMotion {
    /// Shape growing / shrinking. Opening overshoots a touch; closing settles with almost no bounce.
    static func shape(open: Bool, reduceMotion: Bool = false) -> Animation {
        if reduceMotion { return .easeInOut(duration: 0.15) }
        return open
            ? .spring(response: 0.42, dampingFraction: 0.78)
            : .spring(response: 0.36, dampingFraction: 0.92)
    }

    /// Hover feedback (shadow, hover state).
    static let hover: Animation = .interactiveSpring(response: 0.32, dampingFraction: 0.8)

    /// Content appears after the shape has started growing...
    static func contentIn(reduceMotion: Bool = false) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.30).delay(0.12)
    }

    /// ...and leaves before the shape shrinks.
    static let contentOut: Animation = .easeIn(duration: 0.10)
}
