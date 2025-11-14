import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "MuseumMap-8k" asset catalog image resource.
    static let museumMap8K = DeveloperToolsSupport.ImageResource(name: "MuseumMap-8k", bundle: resourceBundle)

    /// The "MuseumMap-thumbnail" asset catalog image resource.
    static let museumMapThumbnail = DeveloperToolsSupport.ImageResource(name: "MuseumMap-thumbnail", bundle: resourceBundle)

    /// The "facing-glyph" asset catalog image resource.
    static let facingGlyph = DeveloperToolsSupport.ImageResource(name: "facing-glyph", bundle: resourceBundle)

    /// The "myFirstFloor_v03-metric" asset catalog image resource.
    static let myFirstFloorV03Metric = DeveloperToolsSupport.ImageResource(name: "myFirstFloor_v03-metric", bundle: resourceBundle)

    /// The "myFirstFloor_v03-metric-thumb" asset catalog image resource.
    static let myFirstFloorV03MetricThumb = DeveloperToolsSupport.ImageResource(name: "myFirstFloor_v03-metric-thumb", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "MuseumMap-8k" asset catalog image.
    static var museumMap8K: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .museumMap8K)
#else
        .init()
#endif
    }

    /// The "MuseumMap-thumbnail" asset catalog image.
    static var museumMapThumbnail: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .museumMapThumbnail)
#else
        .init()
#endif
    }

    /// The "facing-glyph" asset catalog image.
    static var facingGlyph: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .facingGlyph)
#else
        .init()
#endif
    }

    /// The "myFirstFloor_v03-metric" asset catalog image.
    static var myFirstFloorV03Metric: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .myFirstFloorV03Metric)
#else
        .init()
#endif
    }

    /// The "myFirstFloor_v03-metric-thumb" asset catalog image.
    static var myFirstFloorV03MetricThumb: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .myFirstFloorV03MetricThumb)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "MuseumMap-8k" asset catalog image.
    static var museumMap8K: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .museumMap8K)
#else
        .init()
#endif
    }

    /// The "MuseumMap-thumbnail" asset catalog image.
    static var museumMapThumbnail: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .museumMapThumbnail)
#else
        .init()
#endif
    }

    /// The "facing-glyph" asset catalog image.
    static var facingGlyph: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .facingGlyph)
#else
        .init()
#endif
    }

    /// The "myFirstFloor_v03-metric" asset catalog image.
    static var myFirstFloorV03Metric: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .myFirstFloorV03Metric)
#else
        .init()
#endif
    }

    /// The "myFirstFloor_v03-metric-thumb" asset catalog image.
    static var myFirstFloorV03MetricThumb: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .myFirstFloorV03MetricThumb)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

