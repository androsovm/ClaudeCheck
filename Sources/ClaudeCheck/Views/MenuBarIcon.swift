import SwiftUI
import AppKit

/// Menu bar label. Renders the Claude logo (Resources/Claude.svg) tinted by
/// severity color.
///
/// Tinting is applied at the `NSImage` level (we draw the color through the
/// SVG silhouette as a mask) rather than via SwiftUI's `.foregroundStyle` —
/// `MenuBarExtra` labels unreliably propagate `foregroundStyle` to embedded
/// images, which is the same reason the older build used plain emoji.
///
/// Falls back to the emoji dot if the SVG can't be loaded so the app stays
/// usable even if the bundled resource goes missing in a dev build.
struct MenuBarIcon: View {
    let severity: Severity
    let showText: Bool

    var body: some View {
        HStack(spacing: 4) {
            if let logo = Self.tintedLogo(for: severity) {
                Image(nsImage: logo)
            } else {
                Text(severity.emoji)
            }
            if showText {
                Text(severity.shortLabel)
            }
        }
    }

    // MARK: - Tinted logo cache

    private static let logoSize = NSSize(width: 18, height: 18)

    /// The raw SVG, loaded once. macOS 14's `_NSSVGImageRep` renders fine but
    /// reports `size = 1×1` because the source declares `width/height="1em"`;
    /// we have to override `size` or every draw collapses to a single pixel.
    private static let baseLogo: NSImage? = {
        guard let url = Bundle.main.url(forResource: "Claude", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.size = logoSize
        return image
    }()

    private static var tintCache: [Severity: NSImage] = [:]

    static func tintedLogo(for severity: Severity) -> NSImage? {
        if let cached = tintCache[severity] { return cached }
        guard let base = baseLogo else { return nil }
        let color = NSColor(severity.color)
        let tinted = NSImage(size: logoSize, flipped: false) { rect in
            // Fill the whole rect with the target color, then punch out
            // everything outside the logo silhouette using the SVG's alpha
            // as a mask (`destinationIn` keeps dst pixels where src has alpha).
            color.set()
            rect.fill()
            base.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
            return true
        }
        // `isTemplate = false` so macOS doesn't overwrite our color with the
        // system menu-bar tint.
        tinted.isTemplate = false
        tintCache[severity] = tinted
        return tinted
    }
}
