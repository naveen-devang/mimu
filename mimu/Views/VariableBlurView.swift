import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins
import QuartzCore

public enum VariableBlurDirection {
    case blurredTopClearBottom
    case blurredBottomClearTop
}

public struct VariableBlurView: UIViewRepresentable {
    public var maxBlurRadius: CGFloat = 20
    public var direction: VariableBlurDirection = .blurredTopClearBottom
    public var startOffset: CGFloat = 0
    
    public init(maxBlurRadius: CGFloat = 20, direction: VariableBlurDirection = .blurredTopClearBottom, startOffset: CGFloat = 0) {
        self.maxBlurRadius = maxBlurRadius
        self.direction = direction
        self.startOffset = startOffset
    }
    
    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius, direction: direction, startOffset: startOffset)
    }

    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
    }
}

open class VariableBlurUIView: UIVisualEffectView {
    public init(maxBlurRadius: CGFloat = 20, direction: VariableBlurDirection = .blurredTopClearBottom, startOffset: CGFloat = 0) {
        super.init(effect: UIBlurEffect(style: .regular))

        let clsName = String("retliFAC".reversed())
        guard let Cls = NSClassFromString(clsName)! as? NSObject.Type else {
            print("[VariableBlur] Error: Can't find filter class")
            return
        }
        let selName = String(":epyThtiWretlif".reversed())
        guard let variableBlur = Cls.self.perform(NSSelectorFromString(selName), with: "variableBlur").takeUnretainedValue() as? NSObject else {
            print("[VariableBlur] Error: Can't create variableBlur filter")
            return
        }

        let gradientImage = makeGradientImage(startOffset: startOffset, direction: direction)

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImage, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // Use UIVisualEffectView's backdrop layer to apply CAFilters directly onto content underneath
        let backdropLayer = subviews.first?.layer
        backdropLayer?.filters = [variableBlur]
        
        // Recursively strip away all default UIKit color tints and overlay views
        stripTints(self)
    }

    private func stripTints(_ view: UIView) {
        let className = String(describing: type(of: view))
        if className.contains("Backdrop") {
            // Backdrop view itself performs the blur, but we hide its subviews (the tint overlays)
            for subview in view.subviews {
                subview.alpha = 0
                subview.isHidden = true
            }
        } else if view !== self {
            // Hide all other structural effect views (dim/tint layers)
            view.alpha = 0
            view.isHidden = true
        }
        for subview in view.subviews {
            stripTints(subview)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToWindow() {
        guard let window, let backdropLayer = subviews.first?.layer else { return }
        backdropLayer.setValue(window.traitCollection.displayScale, forKey: "scale")
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // super.traitCollectionDidChange(previousTraitCollection) crashes the app
    }
    
    private func makeGradientImage(width: CGFloat = 100, height: CGFloat = 100, startOffset: CGFloat, direction: VariableBlurDirection) -> CGImage {
        let ciGradientFilter = CIFilter.smoothLinearGradient()
        ciGradientFilter.color0 = CIColor.black
        ciGradientFilter.color1 = CIColor.clear
        ciGradientFilter.point0 = CGPoint(x: 0, y: height)
        ciGradientFilter.point1 = CGPoint(x: 0, y: startOffset * height)
        if case .blurredBottomClearTop = direction {
            ciGradientFilter.point0.y = 0
            ciGradientFilter.point1.y = height - ciGradientFilter.point1.y
        }
        return CIContext().createCGImage(ciGradientFilter.outputImage!, from: CGRect(x: 0, y: 0, width: width, height: height))!
    }
}
