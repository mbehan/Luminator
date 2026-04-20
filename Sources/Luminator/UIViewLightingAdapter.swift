
import UIKit
import CoreImage
import ObjectiveC
import QuartzCore

private nonisolated(unsafe) var lightingAdapterKey: UInt8 = 0

/// Adapts a `UIView` to the `LightingRenderable` protocol by rendering a lit overlay image.
@MainActor
public final class UIViewLightingAdapter: NSObject, LightingRenderable {
    /// The view receiving the lighting overlay.
    public weak var view: UIView?
    /// The amount of ambient light applied before additive lights are composited.
    public var ambientLightLevel: Float = 1.0 {
        didSet {
            ambientLightLevel = min(max(ambientLightLevel, 0), 1)
            rerenderIfPossible()
        }
    }

    private let overlayImageView = UIImageView()
    private var sourceImage: UIImage?
    private var sourceAnimationImages: [UIImage] = []
    private var sourceAnimationDuration: TimeInterval = 0
    private var sourceAnimationRepeatCount: Int = 0
    private var sourceIsAnimating = false
    private weak var lightingContext: CIContext?
    private var lastLights: [LightFixture] = []
    private nonisolated(unsafe) var displayLink: CADisplayLink?
    private var currentAnimationFrameIndex = 0
    private var elapsedFrameTime: TimeInterval = 0
    private var completedAnimationLoops = 0

    /// Creates an adapter for the supplied view.
    ///
    /// - Parameter view: The view to render lighting on top of.
    public init(view: UIView) {
        self.view = view
        super.init()
        configureOverlayIfNeeded()
    }

    /// Stores the Core Image context used for future rerenders.
    ///
    /// - Parameter context: The rendering context supplied by a controller.
    public func setLightingContext(_ context: CIContext) {
        lightingContext = context
        configureOverlayIfNeeded()
    }

    /// Applies the provided lights to the adapted view.
    ///
    /// - Parameters:
    ///   - lights: The light fixtures affecting the view.
    ///   - context: The Core Image context used to render the lit result.
    public func applyLights(_ lights: [LightFixture], context: CIContext) {
        lastLights = lights
        guard let view else { return }
        configureOverlayIfNeeded()
        syncSourceImageViewState()

        if view is UIImageView, !sourceAnimationImages.isEmpty {
            applyAnimatedLights(lights: lights, context: context)
            return
        }

        guard let baseImage = captureBaseImage(from: view) else {
            overlayImageView.image = nil
            return
        }

        overlayImageView.applyLights(
            lights,
            baseImage: baseImage,
            ambientLightLevel: ambientLightLevel,
            in: context
        ) { [weak overlayImageView] point in
            guard let overlayImageView, let superview = view.superview else {
                return .zero
            }

            return overlayImageView.convert(point, from: superview)
        }
    }

    private func configureOverlayIfNeeded() {
        guard let view else { return }
        guard overlayImageView.superview == nil else {
            overlayImageView.frame = view.bounds
            return
        }

        overlayImageView.frame = view.bounds
        overlayImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayImageView.contentMode = (view as? UIImageView)?.contentMode ?? .scaleToFill
        overlayImageView.backgroundColor = .clear
        overlayImageView.isUserInteractionEnabled = false
        view.addSubview(overlayImageView)
    }

    private func syncSourceImageViewState() {
        guard let imageView = view as? UIImageView else { return }

        if sourceImage == nil {
            sourceImage = imageView.image
        }

        guard let animationImages = imageView.animationImages, !animationImages.isEmpty else {
            if sourceImage != nil {
                imageView.image = nil
            }
            return
        }

        sourceAnimationImages = animationImages
        sourceAnimationDuration = imageView.animationDuration
        sourceAnimationRepeatCount = imageView.animationRepeatCount
        sourceIsAnimating = imageView.isAnimating
        if displayLink == nil {
            currentAnimationFrameIndex = 0
            elapsedFrameTime = 0
            completedAnimationLoops = 0
        }

        if imageView.isAnimating {
            imageView.stopAnimating()
        }

        imageView.animationImages = nil
        imageView.image = nil
    }

    private func applyAnimatedLights(lights: [LightFixture], context: CIContext) {
        guard !sourceAnimationImages.isEmpty else {
            stopDisplayLink()
            overlayImageView.image = nil
            return
        }

        currentAnimationFrameIndex = min(currentAnimationFrameIndex, max(sourceAnimationImages.count - 1, 0))
        renderAnimatedFrame(at: currentAnimationFrameIndex, lights: lights, context: context)

        if sourceIsAnimating {
            startDisplayLinkIfNeeded()
        } else {
            stopDisplayLink()
        }
    }

    private func rerenderIfPossible() {
        guard let context = lightingContext, view != nil else { return }
        applyLights(lastLights, context: context)
    }

    private func renderAnimatedFrame(at index: Int, lights: [LightFixture], context: CIContext) {
        guard sourceAnimationImages.indices.contains(index),
              let cgImage = sourceAnimationImages[index].cgImage else {
            overlayImageView.image = nil
            return
        }

        let baseImage = CIImage(cgImage: cgImage)
        overlayImageView.image = overlayImageView.renderedLitImage(
            lights,
            baseImage: baseImage,
            ambientLightLevel: ambientLightLevel,
            in: context
        ) { [weak overlayImageView, weak view] point in
            guard let overlayImageView, let view, let superview = view.superview else {
                return .zero
            }

            return overlayImageView.convert(point, from: superview)
        }
    }

    private func startDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(stepAnimation(_:)))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        elapsedFrameTime = 0
    }

    @objc private func stepAnimation(_ displayLink: CADisplayLink) {
        guard let context = lightingContext,
              !sourceAnimationImages.isEmpty,
              sourceAnimationDuration > 0 else {
            stopDisplayLink()
            return
        }

        let frameDuration = sourceAnimationDuration / Double(sourceAnimationImages.count)
        elapsedFrameTime += displayLink.targetTimestamp - displayLink.timestamp

        guard elapsedFrameTime >= frameDuration else {
            return
        }

        elapsedFrameTime = 0
        currentAnimationFrameIndex += 1

        if currentAnimationFrameIndex >= sourceAnimationImages.count {
            currentAnimationFrameIndex = 0
            completedAnimationLoops += 1

            if sourceAnimationRepeatCount > 0 && completedAnimationLoops >= sourceAnimationRepeatCount {
                sourceIsAnimating = false
                stopDisplayLink()
                currentAnimationFrameIndex = max(sourceAnimationImages.count - 1, 0)
            }
        }

        renderAnimatedFrame(at: currentAnimationFrameIndex, lights: lastLights, context: context)
    }

    private func captureBaseImage(from view: UIView) -> CIImage? {
        if view is UIImageView {
            if let cgImage = sourceImage?.cgImage {
                return CIImage(cgImage: cgImage)
            }
        }

        let wasHidden = overlayImageView.isHidden
        overlayImageView.isHidden = true
        defer {
            overlayImageView.isHidden = wasHidden
        }

        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        if let cgImage = image.cgImage {
            return CIImage(cgImage: cgImage)
        }

        return nil
    }

    deinit {
        displayLink?.invalidate()
    }
}

public extension UIView {
    /// A lazily created lighting adapter associated with the view.
    var lightingAdapter: UIViewLightingAdapter {
        if let adapter = objc_getAssociatedObject(self, &lightingAdapterKey) as? UIViewLightingAdapter {
            return adapter
        }

        let adapter = UIViewLightingAdapter(view: self)
        objc_setAssociatedObject(self, &lightingAdapterKey, adapter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return adapter
    }
}
