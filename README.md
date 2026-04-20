# Luminator

`Luminator` composites dynamic light sources over `UIImageView` content, including animations, using Core Image.

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
backgroundImageView.ambientLightLevel = 0.2
view.addSubview(backgroundImageView)
view.addSubview(lightView)

lightingController.addLitView(backgroundImageView)
lightingController.addLightFixture(lightView)
lightingController.setNeedsLightingUpdate()

lightView.onPositionChanged = { [weak self] _ in
    self?.lightingController.setNeedsLightingUpdate()
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
