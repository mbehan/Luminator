import UIKit
import CoreGraphics

/// Describes a light source that can be applied to a renderable view.
@MainActor
public protocol LightFixture {
    /// The light's position in the coordinate space expected by the renderer.
    var position: CGPoint { get }
    /// The light's intensity, typically between `0` and `1`.
    var intensity: NSNumber { get }
    /// The light's effective radius.
    var range: NSNumber { get }
    /// The tint color applied to the light contribution.
    var tintColor: UIColor? { get }
    /// Indicates whether intensity remains constant until the edge of `range`.
    var constantIntensityOverRange: Bool { get }
}
