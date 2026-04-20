//
//  LightView.swift
//

import UIKit
import CoreGraphics

/// A UIView subclass conforming to `LightFixture` protocol representing a light source in the UI.
/// 
/// Use this view to represent a light source that affects lighting effects managed by a `LightingController`.
/// The light's position is by default the view's center in its superview's coordinate space, but can be overridden.
/// The view itself is visually transparent and non-interactive.
/// 
/// Example usage:
/// ```swift
/// let light = LightView(intensity: 0.8, range: 200)
/// someSuperview.addSubview(light)
/// ```
public final class LightView: UIView, LightFixture {
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

    // MARK: - LightFixture Properties
    
    /// The intensity of the light.
    public var intensity: NSNumber
    
    /// The range (radius) of the light.
    public var range: NSNumber
    
    /// The tint color of the light.
    override public var tintColor: UIColor? {
        didSet {
            super.tintColor = tintColor
        }
    }
    
    /// Whether the light intensity remains constant over its range.
    public var constantIntensityOverRange: Bool
    
    /// Backing property for position override.
    private var _positionOverride: CGPoint?

    /// Called whenever the light's visible position changes.
    public var onPositionChanged: ((CGPoint) -> Void)?

    /// Whether the user can drag the light view.
    public var isDraggable: Bool = true {
        didSet {
            panGestureRecognizer.isEnabled = isDraggable
            isUserInteractionEnabled = isDraggable
        }
    }
    
    /// The position of the light in its superview's coordinate space.
    /// Returns the override if set, otherwise the view's center in superview's coordinate space.
    public var position: CGPoint {
        if let override = _positionOverride {
            return override
        }
        guard let superview = superview else { return .zero }
        return superview.convert(center, from: self)
    }
    
    // MARK: - Initializers
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - intensity: The intensity of the light. Defaults to 1.0.
    ///   - range: The range of the light. Defaults to 150.0.
    ///   - tintColor: The tint color of the light. Defaults to `.white`.
    ///   - constantIntensityOverRange: Whether intensity remains constant over range. Defaults to `false`.
    ///   - frame: The frame of the view. Defaults to `.zero`.
    public init(intensity: NSNumber = 1.0,
                range: NSNumber = 150.0,
                tintColor: UIColor = .white,
                constantIntensityOverRange: Bool = false,
                frame: CGRect = .zero) {
        self.intensity = intensity
        self.range = range
        self.constantIntensityOverRange = constantIntensityOverRange
        super.init(frame: frame)
        super.tintColor = tintColor
        commonInit()
    }
    
    /// Required initializer with coder.
    ///
    /// Initializes properties with default values.
    public required init?(coder: NSCoder) {
        self.intensity = 1.0
        self.range = 150.0
        self.constantIntensityOverRange = false
        super.init(coder: coder)
        super.tintColor = tintColor
        commonInit()
    }
    
    /// Returns self as a `LightFixture`.
    ///
    /// - Returns: This view instance typed as `LightFixture`.
    public func asLightFixture() -> LightFixture {
        return self
    }

    // MARK: - Private

    private func commonInit() {
        super.backgroundColor = .clear
        isUserInteractionEnabled = isDraggable
        addGestureRecognizer(panGestureRecognizer)
    }

    @objc private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let superview else { return }

        let translation = gestureRecognizer.translation(in: superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gestureRecognizer.setTranslation(.zero, in: superview)
        onPositionChanged?(position)
    }
}
