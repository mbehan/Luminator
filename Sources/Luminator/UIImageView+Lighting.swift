
import UIKit
import CoreImage

public extension UIImageView {
    /// The ambient light level applied before individual lights are composited.
    var ambientLightLevel: Float {
        get {
            lightingAdapter.ambientLightLevel
        }
        set {
            lightingAdapter.ambientLightLevel = min(max(newValue, 0), 1)
        }
    }

    /// Applies lighting effects to the image view by compositing multiple lights over a base image.
    ///
    /// - Parameters:
    ///   - lights: An array of `LightFixture` objects representing individual lights with position, range, intensity, and tint color.
    ///   - baseImage: The base `CIImage` over which lighting effects are applied.
    ///   - ambientLightLevel: A float between 0 and 1 representing the ambient light level; used to darken the base image.
    ///   - context: The `CIContext` used for rendering `CIImage` to `CGImage`.
    ///   - convertPoint: A closure that converts a `CGPoint` (light position) to the coordinate space of the image view.
    func applyLights(_ lights: [LightFixture], baseImage: CIImage, ambientLightLevel: Float, in context: CIContext, convertPoint: (CGPoint) -> CGPoint) {
        guard let litImage = renderedLitImage(
            lights,
            baseImage: baseImage,
            ambientLightLevel: ambientLightLevel,
            in: context,
            convertPoint: convertPoint
        ) else {
            DispatchQueue.main.async {
                self.image = UIImage(ciImage: baseImage)
            }
            return
        }

        if Thread.isMainThread {
            self.image = litImage
        } else {
            DispatchQueue.main.async {
                self.image = litImage
            }
        }
    }

    /// Renders the lighting effect and returns the composited image without mutating the image view.
    ///
    /// - Parameters:
    ///   - lights: The light fixtures to composite.
    ///   - baseImage: The base image over which lighting effects are applied.
    ///   - ambientLightLevel: A value from `0` to `1` used to darken the base image.
    ///   - context: The Core Image context used to produce the final image.
    ///   - convertPoint: Converts a light position into the image view's coordinate space.
    /// - Returns: A rendered `UIImage` when composition succeeds, otherwise a fallback image.
    func renderedLitImage(_ lights: [LightFixture], baseImage: CIImage, ambientLightLevel: Float, in context: CIContext, convertPoint: (CGPoint) -> CGPoint) -> UIImage? {
        var gradients: [CIImage] = []

        for light in lights {
            guard let tintColor = light.tintColor else { continue }

            let convertedPoint = convertPoint(light.position)
            let flippedPoint = CGPoint(x: convertedPoint.x, y: bounds.height - convertedPoint.y)
            let centerVector = CIVector(x: flippedPoint.x, y: flippedPoint.y)

            let inputRadius0 = light.constantIntensityOverRange ? light.range : NSNumber(value: 0)
            let inputRadius1 = light.range
            let inputColor0 = CIColor(color: tintColor.withAlphaComponent(CGFloat(truncating: light.intensity)))
            let inputColor1 = CIColor(color: tintColor.withAlphaComponent(0))

            guard let gradient = CIFilter(
                name: "CIRadialGradient",
                parameters: [
                    "inputRadius0": inputRadius0,
                    "inputRadius1": inputRadius1,
                    "inputCenter": centerVector,
                    "inputColor0": inputColor0,
                    "inputColor1": inputColor1
                ]
            )?.outputImage else {
                continue
            }

            gradients.append(gradient)
        }

        if gradients.isEmpty {
            return UIImage(ciImage: baseImage)
        }
        
        guard let colorControls = CIFilter(name: "CIColorControls") else {
            return UIImage(ciImage: baseImage)
        }
        colorControls.setValue(baseImage, forKey: kCIInputImageKey)
        colorControls.setValue(-(1 - ambientLightLevel), forKey: kCIInputBrightnessKey)
        colorControls.setValue(1.0, forKey: kCIInputSaturationKey)
        colorControls.setValue(1.0, forKey: kCIInputContrastKey)

        guard var currentOutput = colorControls.outputImage else {
            return UIImage(ciImage: baseImage)
        }

        for gradient in gradients {
            guard let additionFilter = CIFilter(name: "CIAdditionCompositing") else {
                return UIImage(ciImage: baseImage)
            }
            additionFilter.setValue(gradient, forKey: kCIInputImageKey)
            additionFilter.setValue(currentOutput, forKey: kCIInputBackgroundImageKey)
            guard let output = additionFilter.outputImage else {
                return UIImage(ciImage: baseImage)
            }
            currentOutput = output
        }

        guard let sourceInFilter = CIFilter(name: "CISourceInCompositing") else {
            return UIImage(ciImage: baseImage)
        }
        sourceInFilter.setValue(currentOutput, forKey: kCIInputImageKey)
        sourceInFilter.setValue(baseImage, forKey: kCIInputBackgroundImageKey)

        guard let maskedOutput = sourceInFilter.outputImage else {
            return UIImage(ciImage: baseImage)
        }

        if let cgImage = context.createCGImage(maskedOutput, from: baseImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return UIImage(ciImage: baseImage)
    }
}

