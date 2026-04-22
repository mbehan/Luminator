# Luminator

`Luminator` composites dynamic light sources over `UIImageView` content, including animations, using Core Image.

<img width="452" height="592" alt="luminator-demo" src="https://github.com/user-attachments/assets/c54c6abc-3876-4adf-8a41-b6db668a34ab" />

## Requirements

- iOS 13+
- Swift 6

## Installation

Add `Luminator` as a Swift Package dependency in Xcode:

```text
https://github.com/mbehan/Luminator.git
```

Or declare it in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mbehan/Luminator.git", from: "<version>")
]
```

And add the product to your target:

```swift
dependencies: [
    .product(name: "Luminator", package: "Luminator")
]
```

## Quick Start

```swift
import UIKit
import Luminator

class ViewController: UIViewController {
    
    let lightingController = LightingController()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let bg = UIImageView(image: UIImage(named: "background"))
        bg.ambientLightLevel = 0.25
        view.addSubview(bg)
        lightingController.addLitView(bg)
        
        let light = LightView(intensity: 1.0,
                              range: 150.0,
                              tintColor: .white,
                              frame: CGRect(x: 100, y: 100, width: 20, height: 20))
        view.addSubview(light)
        lightingController.addLightFixture(light)
        lightingController.setNeedsLightingUpdate()
    }
}
```

## How It Works

1. Register one or more light sources with `LightingController`.
2. Register any `UIImageView` you want rendered with lighting effects.
3. Call `setNeedsLightingUpdate()` when light positions or properties change.
4. Enable `lightsConstantlyUpdating` when lighting should be recomputed continuously.

`Luminator` ships with `LightView`, a draggable `UIView` that already conforms to `LightFixture`, but any type that provides a position, intensity, range and tint color can be used as a light source.

## Main Types

### `LightingController`

Coordinates light fixtures and lit views.

```swift
let lightingController = LightingController()
lightingController.lightsConstantlyUpdating = false
lightingController.addLightFixture(light)
lightingController.addLitView(imageView)
lightingController.setNeedsLightingUpdate()
```

### `LightView`

A ready-to-use `UIView` light source with:

- `intensity`
- `range`
- `tintColor`
- `constantIntensityOverRange`
- `isDraggable`
- `onPositionChanged`

### `ambientLightLevel`

`UIImageView` exposes an `ambientLightLevel` convenience property:

```swift
imageView.ambientLightLevel = 0.25
```

Use lower values for darker scenes and higher values to preserve more of the original image.

## Using Custom Lights

Any type conforming to `LightFixture` can act as a light:

```swift
import UIKit
import Luminator

struct CustomLight: LightFixture {
    var position: CGPoint
    var intensity: NSNumber
    var range: NSNumber
    var tintColor: UIColor?
    var constantIntensityOverRange: Bool
}
```

## Notes

- Rendering is based on Core Image filters including `CIRadialGradient`, `CIAdditionCompositing`, and `CISourceInCompositing`
- `UIImageView` animation frames are supported
- For static scenes, prefer explicit invalidation with `setNeedsLightingUpdate()` instead of continuous updates
- Experimental `UIView` support is available via `UIViewLightingAdapter` and provides the same interface as `UIImageView`
- The original approach, which provides custom classes rather than extending UIImageView, and is written in Objective-C, is retained on the `objc` branch
