import UIKit
import CoreImage
import Metal

@objcMembers
/// Coordinates light sources and lit views, then applies lighting updates on the main run loop.
@MainActor
public class LightingController: NSObject {
    /// Controls whether lighting is recomputed continuously or only after explicit invalidation.
    public var lightsConstantlyUpdating: Bool = false
    
    private let coreImageContext: CIContext
    private var needsLightingUpdate: Bool = false
    private var lightFixtures: [LightFixture] = []
    private var litRenderables: [LightingRenderable] = []
    private nonisolated(unsafe) var timer: Timer?
    
    /// Creates a lighting controller backed by a Core Image context.
    public override init() {
        if let device = MTLCreateSystemDefaultDevice() {
            let options: [CIContextOption: Any] = [
                .workingColorSpace: NSNull()
            ]
            coreImageContext = CIContext(mtlDevice: device, options: options)
        } else {
            let options: [CIContextOption: Any] = [
                .workingColorSpace: NSNull()
            ]
            coreImageContext = CIContext(options: options)
        }
        
        super.init()
        
        let timer = Timer(timeInterval: 0.1, target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    /// Registers a light source that contributes to subsequent renders.
    ///
    /// - Parameter light: The light fixture to track.
    public func addLightFixture(_ light: LightFixture) {
        lightFixtures.append(light)
    }

    /// Registers a view to receive lighting updates.
    ///
    /// - Parameter litView: A view that should be rendered with lighting effects.
    public func addLitView(_ litView: UIView) {
        let adapter = litView.lightingAdapter
        adapter.setLightingContext(coreImageContext)
        litRenderables.append(adapter)
    }
    
    /// Marks the controller as needing a lighting refresh on the next update pass.
    public func setNeedsLightingUpdate() {
        needsLightingUpdate = true
    }
    
    /// Applies the current set of lights to each registered renderable when an update is needed.
    @objc
    public func updateLighting() {
        guard needsLightingUpdate || lightsConstantlyUpdating else {
            return
        }
        
        needsLightingUpdate = false
        
        for renderable in litRenderables {
            renderable.applyLights(lightFixtures, context: coreImageContext)
        }
    }

    @objc private func timerFired(_ timer: Timer) {
        updateLighting()
    }

    deinit {
        timer?.invalidate()
    }
}
