//
//  CremaPourView.swift
//  Crema
//
//  Launch animation: the notch grows into a cup, espresso pours in and fills it,
//  a crema layer forms between the espresso and the notch, then the cup
//  retracts back into the notch, leaving the closed notch (with its crema rim).
//

import SwiftUI

/// Pure timeline for the pour. All times are in seconds of *unscaled* animation time.
struct CremaPourTimeline {
    static let duration: Double = 4.0
    static let retractStart: Double = 3.0
    static let retractEnd: Double = 3.7
    static let fadeEnd: Double = 4.0

    let t: Double

    private func seg(_ a: Double, _ b: Double) -> Double { min(1, max(0, (t - a) / (b - a))) }
    private func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }

    /// Spring with a slight overshoot, like the real notch opening.
    var shape: Double {
        let x = min(1, max(0, t / 0.9))
        let open = x >= 1 ? 1 : 1 - exp(-7 * x) * cos(9 * x)
        return open * (1 - retract)
    }
    /// The cup draws back up into the notch.
    var retract: Double {
        let x = seg(Self.retractStart, Self.retractEnd)
        return x * x * (3 - 2 * x)
    }
    var espresso: Double { easeOut(seg(0.35, 1.9)) }
    var crema: Double { easeOut(seg(1.7, 2.8)) }
    var stream: Double { seg(0.2, 0.35) * (1 - seg(1.8, 2.0)) }
    var settle: Double { 1 - seg(1.9, 3.2) }
    var cremaSettle: Double { 1 - seg(2.8, 3.6) }
    var dissolve: Double { easeOut(seg(Self.retractEnd, Self.fadeEnd)) }
}

struct CremaPourView: View {
    /// Size of the cup body that hangs below the menu bar strip: as wide as the notch, and deep like a cup.
    private var cupSize: CGSize { CGSize(width: closedSize.width + 4, height: 104) }

    /// 1 plays at the designed speed; larger plays faster (used after the first launch).
    var timeScale: Double = 1
    var closedSize: CGSize
    var onFinish: () -> Void

    @State private var start = Date()

    private let espressoColor = CremaPalette.espresso
    private let cremaColor = CremaPalette.crema
    private let cremaSurface = CremaPalette.cremaSurface
    private let bubbleLight = Color(red: 0.96, green: 0.86, blue: 0.68)
    private let bubbleDark = Color(red: 0.54, green: 0.33, blue: 0.14)

    var body: some View {
        TimelineView(.animation) { context in
            let t = max(0, context.date.timeIntervalSince(start)) * timeScale
            let tl = CremaPourTimeline(t: t)
            Canvas { gc, size in
                draw(&gc, size: size, tl: tl, t: t)
            }
            .opacity(1 - tl.dissolve)
        }
        .frame(width: cupSize.width + 40, height: closedSize.height + cupSize.height + 12)
        .allowsHitTesting(false)
        .task {
            start = Date()
            try? await Task.sleep(for: .seconds(CremaPourTimeline.duration / timeScale))
            onFinish()
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ p: CGFloat) -> CGFloat { a + (b - a) * p }

    private func draw(_ gc: inout GraphicsContext, size: CGSize, tl: CremaPourTimeline, t: Double) {
        let p = max(0, CGFloat(tl.shape))
        // The cup hangs from the notch: it stays notch-width inside the menu bar strip
        // (height `mb`) so menu items stay visible, and only widens below it.
        let mb = closedSize.height
        let nw = closedSize.width
        let bodyW = lerp(nw, cupSize.width, p)
        let bodyH = max(0, lerp(0, cupSize.height, p))
        let h = mb + bodyH
        let top = cornerRadiusInsets.closed.top
        let rTop = min(10, bodyH / 2)
        let rBot = min(18, bodyH / 2, bodyW / 2)
        let cx = size.width / 2
        let nL = cx - nw / 2, nR = cx + nw / 2
        let x0 = cx - bodyW / 2, x1 = cx + bodyW / 2

        var shell = Path()
        shell.move(to: CGPoint(x: nL - top, y: 0))
        shell.addQuadCurve(to: CGPoint(x: nL, y: top), control: CGPoint(x: nL, y: 0))
        shell.addLine(to: CGPoint(x: nL, y: mb))
        shell.addLine(to: CGPoint(x: x0 + rTop, y: mb))
        shell.addQuadCurve(to: CGPoint(x: x0, y: mb + rTop), control: CGPoint(x: x0, y: mb))
        shell.addLine(to: CGPoint(x: x0, y: h - rBot))
        shell.addQuadCurve(to: CGPoint(x: x0 + rBot, y: h), control: CGPoint(x: x0, y: h))
        shell.addLine(to: CGPoint(x: x1 - rBot, y: h))
        shell.addQuadCurve(to: CGPoint(x: x1, y: h - rBot), control: CGPoint(x: x1, y: h))
        shell.addLine(to: CGPoint(x: x1, y: mb + rTop))
        shell.addQuadCurve(to: CGPoint(x: x1 - rTop, y: mb), control: CGPoint(x: x1, y: mb))
        shell.addLine(to: CGPoint(x: nR, y: mb))
        shell.addLine(to: CGPoint(x: nR, y: top))
        shell.addQuadCurve(to: CGPoint(x: nR + top, y: 0), control: CGPoint(x: nR, y: 0))
        shell.closeSubpath()
        gc.fill(shell, with: .color(.black))

        gc.clip(to: shell)

        let e = CGFloat(tl.espresso), c = CGFloat(tl.crema)
        // Liquid levels are fractions of the hanging body; crema ends up just under the notch.
        let yE = h - e * 0.60 * bodyH
        let yC = yE - c * 0.26 * bodyH
        let ampE = (1 - e) * 5 + CGFloat(tl.settle) * 1.6
        let ampC = c * CGFloat(tl.cremaSettle) * 3 + 0.6
        let ph = CGFloat(t) * 5

        func wave(_ x: CGFloat, _ base: CGFloat, _ amp: CGFloat, _ phase: CGFloat) -> CGFloat {
            base + amp * sin(x * 0.035 + phase)
        }

        // Liquid edges are sampled once, at the same x positions, and run past the cup walls (the
        // clip trims them), so the espresso, the crema and the sides never leave black slivers.
        let xa = x0 - 24, xb = x1 + 24, n = 48
        func edge(_ base: CGFloat, _ amp: CGFloat, _ phase: CGFloat) -> [CGPoint] {
            (0...n).map { i in
                let x = xa + (xb - xa) * CGFloat(i) / CGFloat(n)
                return CGPoint(x: x, y: wave(x, base, amp, phase))
            }
        }
        let espEdge = edge(yE, ampE, ph)

        // Espresso.
        if e > 0.005 {
            var path = Path()
            path.move(to: CGPoint(x: xa, y: h + 8))
            for pt in espEdge { path.addLine(to: pt) }
            path.addLine(to: CGPoint(x: xb, y: h + 8))
            path.closeSubpath()
            gc.fill(path, with: .color(espressoColor))
        }

        // Crema layer between the espresso and the notch, with a pale surface line.
        if c > 0.01 {
            let cph = ph * 0.7 + 1
            let cremaEdge = edge(yC, ampC, cph)

            // The crema's underside is the espresso's top edge, nudged down so the layers overlap.
            var body = Path()
            body.move(to: cremaEdge[0])
            for pt in cremaEdge.dropFirst() { body.addLine(to: pt) }
            for pt in espEdge.reversed() { body.addLine(to: CGPoint(x: pt.x, y: pt.y + 2)) }
            body.closeSubpath()
            gc.fill(body, with: .color(cremaColor))

            let lip = max(2, c * 7)
            var surface = Path()
            surface.move(to: cremaEdge[0])
            for pt in cremaEdge.dropFirst() { surface.addLine(to: pt) }
            for pt in cremaEdge.reversed() { surface.addLine(to: CGPoint(x: pt.x, y: pt.y + lip)) }
            surface.closeSubpath()
            gc.fill(surface, with: .color(cremaSurface))

            // Fine bubbles.
            for i in 0..<34 {
                let fx = CGFloat((i * 37) % 100) / 100
                let fy = CGFloat((i * 53) % 100) / 100
                let r = 1.6 + CGFloat((i * 17) % 10) / 6
                let bx = x0 + top + 14 + fx * (bodyW - 2 * top - 28)
                let by = yC + 6 + fy * max(1, yE - yC - 10) + CGFloat(sin(t * 2 + Double(i))) * 0.8
                let rect = CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)
                gc.fill(Path(ellipseIn: rect), with: .color((i % 3 == 0 ? bubbleDark : bubbleLight).opacity(Double(c) * 0.55)))
            }
        }

        // Espresso stream falling from the notch.
        if tl.stream > 0.01 {
            let rect = CGRect(x: size.width / 2 - 3, y: 0, width: 6, height: max(0, yE + 2))
            gc.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(espressoColor.opacity(tl.stream)))
        }
    }
}

#Preview {
    CremaPourView(closedSize: CGSize(width: 185, height: 32), onFinish: {})
        .background(.gray)
}
