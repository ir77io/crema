#!/usr/bin/env swift
// Generates Crema's app icon set and logo images. Run from the repo root:
//   swift scripts/make_brand.swift
import AppKit

let assets = "Crema/Assets.xcassets"

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // macOS icon grid: 824/1024 squircle with transparent margin.
    let inset = s * 100 / 1024
    let body = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let squircle = NSBezierPath(roundedRect: body, xRadius: body.width * 0.225, yRadius: body.width * 0.225)
    ctx.saveGState()
    squircle.addClip()

    // Espresso background.
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [NSColor(red: 0.30, green: 0.17, blue: 0.10, alpha: 1).cgColor,
                                 NSColor(red: 0.12, green: 0.07, blue: 0.04, alpha: 1).cgColor] as CFArray,
                        locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: s / 2, y: body.maxY), end: CGPoint(x: s / 2, y: body.minY), options: [])
    // Warm glow behind the cup so the dark espresso stands out.
    let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [NSColor(red: 0.62, green: 0.38, blue: 0.20, alpha: 0.85).cgColor,
                                   NSColor(red: 0.62, green: 0.38, blue: 0.20, alpha: 0).cgColor] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: s / 2, y: body.minY + body.width * 0.52), startRadius: 0,
                           endCenter: CGPoint(x: s / 2, y: body.minY + body.width * 0.52), endRadius: body.width * 0.50, options: [])

    // Glass espresso cup, side view: clear glass, dark espresso, crema layer on top.
    let u = body.width
    let cx = body.midX
    let rgb = CGColorSpaceCreateDeviceRGB()
    let yBot = body.minY + u * 0.30, yTop = body.minY + u * 0.74
    let rt = u * 0.27, rb = u * 0.21
    let wall = u * 0.014, baseT = u * 0.045
    let yEsp = body.minY + u * 0.52, yCrema = body.minY + u * 0.62
    let surfRy = u * 0.026
    func hw(_ y: CGFloat) -> CGFloat { rb + (rt - rb) * (y - yBot) / (yTop - yBot) }
    func glassStroke(_ a: CGFloat) { NSColor(white: 1, alpha: a).setStroke() }
    func glassFill(_ a: CGFloat) { NSColor(white: 1, alpha: a).setFill() }

    // Shadow and glass saucer.
    NSColor(white: 0, alpha: 0.32).setFill()
    NSBezierPath(ovalIn: CGRect(x: cx - u * 0.43, y: yBot - u * 0.115, width: u * 0.86, height: u * 0.14)).fill()
    let sRx = u * 0.44, sRy = u * 0.085, sCy = yBot - u * 0.012
    glassFill(0.22)
    NSBezierPath(ovalIn: CGRect(x: cx - sRx, y: sCy - sRy - u * 0.016, width: sRx * 2, height: sRy * 2)).fill()
    glassFill(0.16)
    let saucerTop = NSBezierPath(ovalIn: CGRect(x: cx - sRx, y: sCy - sRy, width: sRx * 2, height: sRy * 2))
    saucerTop.fill()
    glassStroke(0.55); saucerTop.lineWidth = u * 0.008; saucerTop.stroke()
    let well = NSBezierPath(ovalIn: CGRect(x: cx - u * 0.30, y: sCy - u * 0.052, width: u * 0.60, height: u * 0.104))
    glassStroke(0.28); well.lineWidth = u * 0.006; well.stroke()

    // Glass handle.
    let handle = NSBezierPath()
    handle.move(to: CGPoint(x: cx + hw(yBot + u * 0.33), y: yBot + u * 0.33))
    handle.curve(to: CGPoint(x: cx + hw(yBot + u * 0.09), y: yBot + u * 0.09),
                 controlPoint1: CGPoint(x: cx + u * 0.43, y: yBot + u * 0.37),
                 controlPoint2: CGPoint(x: cx + u * 0.42, y: yBot + u * 0.03))
    handle.lineCapStyle = .round
    handle.lineWidth = u * 0.040; glassStroke(0.18); handle.stroke()
    handle.lineWidth = u * 0.020; glassStroke(0.55); handle.stroke()

    // Cup outline and interior.
    let outline = NSBezierPath()
    outline.move(to: CGPoint(x: cx - rt, y: yTop))
    outline.line(to: CGPoint(x: cx - rb, y: yBot))
    outline.line(to: CGPoint(x: cx + rb, y: yBot))
    outline.line(to: CGPoint(x: cx + rt, y: yTop))
    outline.close()
    glassFill(0.07); outline.fill()

    let yIn = yBot + baseT
    let inner = NSBezierPath()
    inner.move(to: CGPoint(x: cx - hw(yTop) + wall, y: yTop))
    inner.line(to: CGPoint(x: cx - hw(yIn) + wall, y: yIn))
    inner.line(to: CGPoint(x: cx + hw(yIn) - wall, y: yIn))
    inner.line(to: CGPoint(x: cx + hw(yTop) - wall, y: yTop))
    inner.close()

    ctx.saveGState()
    inner.addClip()
    let wide = CGRect(x: cx - rt, y: yIn - u * 0.03, width: rt * 2, height: u * 0.8)
    // Espresso.
    let espGrad = CGGradient(colorsSpace: rgb, colors: [NSColor(red: 0.07, green: 0.03, blue: 0.02, alpha: 1).cgColor,
                                                        NSColor(red: 0.17, green: 0.08, blue: 0.04, alpha: 1).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(espGrad, start: CGPoint(x: cx, y: yIn), end: CGPoint(x: cx, y: yEsp), options: [])
    // Crema band with a gently curved lower boundary.
    let cremaColors = [NSColor(red: 0.70, green: 0.42, blue: 0.17, alpha: 1).cgColor,
                       NSColor(red: 0.88, green: 0.63, blue: 0.32, alpha: 1).cgColor,
                       NSColor(red: 0.96, green: 0.82, blue: 0.58, alpha: 1).cgColor] as CFArray
    let cremaGrad = CGGradient(colorsSpace: rgb, colors: cremaColors, locations: [0, 0.55, 1])!
    ctx.saveGState()
    let band = NSBezierPath(rect: CGRect(x: wide.minX, y: yEsp, width: wide.width, height: yCrema - yEsp))
    band.append(NSBezierPath(ovalIn: CGRect(x: cx - hw(yEsp), y: yEsp - surfRy, width: hw(yEsp) * 2, height: surfRy * 2)))
    band.append(NSBezierPath(ovalIn: CGRect(x: cx - hw(yCrema), y: yCrema - surfRy, width: hw(yCrema) * 2, height: surfRy * 2)))
    band.addClip()
    ctx.drawLinearGradient(cremaGrad, start: CGPoint(x: cx, y: yEsp - surfRy), end: CGPoint(x: cx, y: yCrema + surfRy), options: [])
    // Fine bubble texture.
    var seed: UInt64 = 11
    func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 33) / CGFloat(1 << 31) }
    for i in 0..<520 {
        let x = cx - rt + rnd() * rt * 2
        let y = yEsp - surfRy + rnd() * (yCrema - yEsp + surfRy * 2)
        let r = u * (0.0014 + rnd() * 0.0022)
        (i % 2 == 0 ? NSColor(red: 1, green: 0.93, blue: 0.75, alpha: 0.35) : NSColor(red: 0.45, green: 0.24, blue: 0.08, alpha: 0.30)).setFill()
        NSBezierPath(ovalIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)).fill()
    }
    ctx.restoreGState()
    // Pale surface ellipse on top of the crema.
    NSColor(red: 0.97, green: 0.86, blue: 0.64, alpha: 0.95).setFill()
    NSBezierPath(ovalIn: CGRect(x: cx - hw(yCrema) + wall, y: yCrema - surfRy * 0.8, width: (hw(yCrema) - wall) * 2, height: surfRy * 1.6)).fill()
    ctx.restoreGState()

    // Thick glass base and highlights.
    glassFill(0.20)
    NSBezierPath(rect: CGRect(x: cx - rb, y: yBot, width: rb * 2, height: baseT)).fill()
    glassStroke(0.60); outline.lineWidth = u * 0.009; outline.lineJoinStyle = .round; outline.stroke()
    let rimTop = NSBezierPath(ovalIn: CGRect(x: cx - rt, y: yTop - surfRy, width: rt * 2, height: surfRy * 2))
    glassStroke(0.65); rimTop.lineWidth = u * 0.008; rimTop.stroke()
    let hl = NSBezierPath()
    hl.lineCapStyle = .round; hl.lineWidth = u * 0.016
    hl.move(to: CGPoint(x: cx - rt + u * 0.04, y: yTop - u * 0.05))
    hl.line(to: CGPoint(x: cx - rb + u * 0.035, y: yBot + baseT + u * 0.02))
    glassStroke(0.38); hl.stroke()

    // Physical notch cutout at top.
    let nw = body.width * 0.30, nh = body.height * 0.075
    let notch = NSBezierPath(roundedRect: CGRect(x: body.midX - nw / 2, y: body.maxY - nh, width: nw, height: nh * 1.6),
                             xRadius: nh * 0.8, yRadius: nh * 0.8)
    NSColor.black.setFill()
    notch.fill()

    ctx.restoreGState()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func write(_ data: Data, _ path: String) {
    try! data.write(to: URL(fileURLWithPath: path))
}

// App icon set: rewrite Contents.json with clean filenames.
let iconDir = "\(assets)/AppIcon.appiconset"
let fm = FileManager.default
for f in try! fm.contentsOfDirectory(atPath: iconDir) where f.hasSuffix(".png") { try! fm.removeItem(atPath: "\(iconDir)/\(f)") }
var images: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        write(render(size * scale), "\(iconDir)/\(name)")
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
write(try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]), "\(iconDir)/Contents.json")

// In-app logos reuse the icon.
write(render(256), "\(assets)/logo.imageset/256-mac 1.png")
write(render(512), "\(assets)/logo2.imageset/Crema icon.png")
// Wordmark shown on the welcome screen.
let wmDir = "\(assets)/cremalogo.imageset"
try? fm.removeItem(atPath: "\(wmDir)/CremaLogo.svg")
let wmW = 534, wmH = 110
let wm = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: wmW, pixelsHigh: wmH, bitsPerSample: 8, samplesPerPixel: 4,
                          hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: wm)
let font = NSFont.systemFont(ofSize: 84, weight: .heavy).fontDescriptor.withDesign(.rounded)
    .flatMap { NSFont(descriptor: $0, size: 84) } ?? NSFont.boldSystemFont(ofSize: 84)
let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(red: 0.96, green: 0.84, blue: 0.62, alpha: 1), .kern: 4]
let str = NSAttributedString(string: "crema", attributes: attrs)
let sz = str.size()
str.draw(at: CGPoint(x: (CGFloat(wmW) - sz.width) / 2, y: (CGFloat(wmH) - sz.height) / 2))
NSGraphicsContext.restoreGraphicsState()
write(wm.representation(using: .png, properties: [:])!, "\(wmDir)/CremaLogo.png")
let wmContents: [String: Any] = ["images": [["filename": "CremaLogo.png", "idiom": "universal"]], "info": ["author": "xcode", "version": 1]]
write(try! JSONSerialization.data(withJSONObject: wmContents, options: [.prettyPrinted, .sortedKeys]), "\(wmDir)/Contents.json")
print("done")
