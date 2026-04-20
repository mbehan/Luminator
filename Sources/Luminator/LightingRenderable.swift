import CoreImage

/// Represents an object that can render one or more light fixtures onto itself.
@MainActor
public protocol LightingRenderable: AnyObject {
    /// Provides the Core Image context used for future rendering work.
    ///
    /// - Parameter context: The rendering context supplied by the controller.
    func setLightingContext(_ context: CIContext)
    /// Applies the provided lights using the supplied rendering context.
    ///
    /// - Parameters:
    ///   - lights: The light fixtures affecting the receiver.
    ///   - context: The Core Image context to use for rendering.
    func applyLights(_ lights: [LightFixture], context: CIContext)
}
