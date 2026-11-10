// Draws GranPad's icons: `swift mac/icon.swift <output dir>` writes AppIcon.iconset/, MenuBarIcon(@2x).png
// and the iPad app's AppIcon76x76(@2x).png and AppIcon83.5x83.5@2x.png.
// The logo: a Mac display with an iPad in front of it, extending it; the iPad is an old gentleman ("Gran'Pa")
// with reading glasses and a moustache.
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])

func png(_ size: Int, _ name: String, draw: (CGFloat) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(CGFloat(size))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, scale s: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x * s, y: y * s, width: w * s, height: h * s), xRadius: r * s, yRadius: r * s)
}

func color(_ hex: Int, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

/// App icon on Apple's 1024 grid (824 pt rounded square, 100 pt margin), drawn at `size` pixels.
func appIcon(_ size: CGFloat) {
    let s = size / 1024
    let tile = rect(100, 100, 824, 824, 185, scale: s)
    NSGraphicsContext.saveGraphicsState()
    let tileShadow = NSShadow()
    tileShadow.shadowColor = color(0x000000, 0.35)
    tileShadow.shadowOffset = NSSize(width: 0, height: -12 * s)
    tileShadow.shadowBlurRadius = 24 * s
    tileShadow.set()
    color(0x2B2FB8).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: color(0x5B8CFF), ending: color(0x2A22A8))!.draw(in: tile, angle: -90)
    motif(s)
}

/// The Mac display and the iPad, on the same 1024 grid (`s` = pixels per point).
func motif(_ s: CGFloat) {
    // The motif spans x 196...840, y 246...770: shrink it around its center so it breathes inside the tile.
    let motif = NSAffineTransform()
    motif.translateX(by: 512 * s, yBy: 512 * s)
    motif.scale(by: 0.82)
    motif.translateX(by: -518 * s, yBy: -508 * s)
    motif.concat()

    // Mac display, behind.
    let mac = rect(196, 452, 492, 318, 34, scale: s)
    color(0xFFFFFF, 0.14).setFill()
    mac.fill()
    color(0xFFFFFF, 0.75).setStroke()
    mac.lineWidth = 30 * s
    mac.stroke()
    color(0xFFFFFF, 0.75).setFill()
    rect(410, 380, 64, 72, 0, scale: s).fill()
    rect(344, 352, 196, 34, 17, scale: s).fill()

    // iPad, in front, landscape, with a soft shadow and a glowing screen.
    let pad = rect(420, 246, 420, 300, 46, scale: s)
    NSGraphicsContext.saveGraphicsState()
    let padShadow = NSShadow()
    padShadow.shadowColor = color(0x0B0A4A, 0.55)
    padShadow.shadowOffset = NSSize(width: 0, height: -18 * s)
    padShadow.shadowBlurRadius = 40 * s
    padShadow.set()
    color(0xFFFFFF).setFill()
    pad.fill()
    NSGraphicsContext.restoreGraphicsState()
    let screen = rect(448, 274, 364, 244, 22, scale: s)
    NSGradient(starting: color(0x7FE3FF), ending: color(0x6D5BFF))!.draw(in: screen, angle: -60)

    // Gran'Pa: the iPad is the head, looking over its reading glasses, moustache hanging below.
    let ink = color(0x1E1A5C)
    ink.setFill()
    for x: CGFloat in [562, 698] {
        NSBezierPath(ovalIn: NSRect(x: (x - 17) * s, y: 462 * s, width: 34 * s, height: 34 * s)).fill()
    }
    readingGlasses(630, 400, r: 66, gap: 26, reach: 238, hook: 24, lineWidth: 16, ink: ink,
                   lens: color(0xFFFFFF, 0.35), scale: s)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x000000, 0.25)
    shadow.shadowOffset = NSSize(width: 0, height: -4 * s)
    shadow.shadowBlurRadius = 6 * s
    shadow.set()
    color(0xFFFFFF).setFill()
    moustache(630, 262, 175, scale: s).fill()
    NSGraphicsContext.restoreGraphicsState()
}

/// Half-moon reading glasses: lenses under the line `cy`, temples out to `reach` from the center, then a hook
/// down over the ears.
func readingGlasses(_ cx: CGFloat, _ cy: CGFloat, r: CGFloat, gap: CGFloat, reach: CGFloat, hook: CGFloat,
                    lineWidth: CGFloat, ink: NSColor, lens: NSColor?, scale s: CGFloat) {
    let frame = NSBezierPath()
    for side: CGFloat in [-1, 1] {
        let c = cx + side * (r + gap / 2)
        let glass = NSBezierPath()
        glass.appendArc(withCenter: NSPoint(x: c * s, y: cy * s), radius: r * s, startAngle: 180, endAngle: 360)
        glass.close()
        if let lens {
            lens.setFill()
            glass.fill()
        }
        frame.append(glass)
        frame.move(to: NSPoint(x: (cx + side * (gap / 2 + 2 * r)) * s, y: cy * s))
        frame.line(to: NSPoint(x: (cx + side * reach) * s, y: (cy + hook / 3) * s))
        if hook > 0 { frame.line(to: NSPoint(x: (cx + side * (reach + hook / 2)) * s, y: (cy - hook) * s)) }
    }
    frame.move(to: NSPoint(x: (cx - gap / 2) * s, y: cy * s))
    frame.line(to: NSPoint(x: (cx + gap / 2) * s, y: cy * s))
    ink.setStroke()
    frame.lineWidth = lineWidth * s
    frame.lineCapStyle = .round
    frame.lineJoinStyle = .round
    frame.stroke()
}

/// Bushy moustache centered on (cx, cy), `w` = half width; the tips curl up.
func moustache(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, scale s: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    for side: CGFloat in [1, -1] {
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: (cx + side * x * w) * s, y: (cy + y * w) * s) }
        path.move(to: p(0, 0.10))
        path.curve(to: p(0.78, 0.12), controlPoint1: p(0.20, 0.42), controlPoint2: p(0.58, 0.40))
        path.curve(to: p(1.02, 0.32), controlPoint1: p(0.92, -0.02), controlPoint2: p(1.06, 0.12))
        path.curve(to: p(0.52, -0.20), controlPoint1: p(1.04, -0.04), controlPoint2: p(0.84, -0.24))
        path.curve(to: p(0, -0.02), controlPoint1: p(0.28, -0.17), controlPoint2: p(0.10, -0.10))
        path.close()
    }
    return path
}

/// iPad app icon: the same tile, square and full-bleed (iOS rounds the corners itself).
func iosIcon(_ size: CGFloat) {
    NSGradient(starting: color(0x5B8CFF), ending: color(0x2A22A8))!
        .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)
    let zoom = NSAffineTransform()  // the 824 pt tile (100...924) onto the whole square
    zoom.scale(by: 1024 / 824)
    zoom.translateX(by: -100 * size / 1024, yBy: -100 * size / 1024)
    zoom.concat()
    motif(size / 1024)
}

/// Menu bar template image on an 18 pt grid: black silhouette, macOS tints it.
func menuBarIcon(_ size: CGFloat) {
    let s = size / 18
    NSColor.black.setStroke()
    let mac = rect(1.25, 6.75, 11.5, 8.5, 1.6, scale: s)
    mac.lineWidth = 1.1 * s
    mac.stroke()
    // Clear a gap around the iPad so the two shapes stay distinct at 18 pt.
    NSGraphicsContext.current!.compositingOperation = .clear
    rect(5.9, 1.4, 12, 9.7, 2.6, scale: s).fill()
    NSGraphicsContext.current!.compositingOperation = .sourceOver
    let pad = rect(7.25, 2.75, 10, 7, 1.8, scale: s)
    pad.lineWidth = 1.1 * s
    pad.stroke()
    NSColor.black.setFill()
    NSBezierPath(ovalIn: NSRect(x: 14.75 * s, y: 5.75 * s, width: 1 * s, height: 1 * s)).fill()  // home button
}

let iconset = output.appendingPathComponent("AppIcon.iconset")
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        png(points * scale, "AppIcon.iconset/icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png", draw: appIcon)
    }
}
png(18, "MenuBarIcon.png", draw: menuBarIcon)
png(36, "MenuBarIcon@2x.png", draw: menuBarIcon)
png(76, "AppIcon76x76.png", draw: iosIcon)
png(152, "AppIcon76x76@2x.png", draw: iosIcon)
png(167, "AppIcon83.5x83.5@2x.png", draw: iosIcon)
