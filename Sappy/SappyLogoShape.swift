//
//  SappyLogoShape.swift
//  Sappy
//
//  Created by Neuval Studio on 24/03/2026.
//

import SwiftUI

// MARK: - Sappy Logo Vector Shape

/// A SwiftUI `Shape` that renders the Sappy `):)` logo from raw cubic Bézier path data.
///
/// ## Coordinate System
/// The path data originates from an SVG export with a viewBox roughly spanning
/// `(202.6, 198.5)` to `(306.5, 332.4)` — a `104×134` unit region.
/// The `path(in:)` method normalizes these coordinates into the provided `rect`,
/// applying uniform scaling and centering.
///
/// ## Three Independently Drawable Sub-Paths
/// The logo is composed of three elements that can be toggled independently,
/// enabling partial drawing for animation:
///
/// | Flag        | Sub-Path       | Visual        |
/// |-------------|----------------|---------------|
/// | `drawRight` | Right arc      | `)` — happy   |
/// | `drawColon` | Two dots       | `:` — eyes    |
/// | `drawLeft`  | Left arc       | `)` — sad     |
///
/// ### Composition Examples
/// - **Full logo** `):)`: `drawLeft: true, drawColon: true, drawRight: true`
/// - **Happy face** `:)`: `drawLeft: false, drawColon: true, drawRight: true`
/// - **Sad face** `):`: `drawLeft: true, drawColon: true, drawRight: false`
///
/// ## Static Bounds Contract
/// `fullBounds` is hardcoded to the union bounding box of all three sub-paths.
/// This ensures that partial compositions (e.g., colon-only) are positioned
/// identically to the full logo — critical for the `TrackingView` split animation
/// where faces must share the same spatial origin before separating.
struct SappyLogoShape: Shape {
    var drawLeft: Bool = true
    var drawColon: Bool = true
    var drawRight: Bool = true

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // MARK: Right Arc `)` — Happy

        if drawRight {
            path.move(to: CGPoint(x: 306.548492, y: 264.841003))
            path.addCurve(to: CGPoint(x: 305.561493, y: 247.92099), control1: CGPoint(x: 306.548492, y: 263.431), control2: CGPoint(x: 306.407501, y: 261.174988))
            path.addLine(to: CGPoint(x: 304.29248, y: 235.653992))
            path.addCurve(to: CGPoint(x: 299.639496, y: 213.234985), control1: CGPoint(x: 303.728516, y: 231.424011), control2: CGPoint(x: 303.023499, y: 227.194))
            path.addCurve(to: CGPoint(x: 292.730499, y: 200.403992), control1: CGPoint(x: 298.652496, y: 210.273987), control2: CGPoint(x: 297.524506, y: 207.735992))
            path.addCurve(to: CGPoint(x: 288.500488, y: 198.570984), control1: CGPoint(x: 291.320496, y: 199.276001), control2: CGPoint(x: 289.910522, y: 198.570984))
            path.addCurve(to: CGPoint(x: 283.565491, y: 200.544983), control1: CGPoint(x: 286.385498, y: 198.570984), control2: CGPoint(x: 284.693481, y: 199.276001))
            path.addCurve(to: CGPoint(x: 281.732483, y: 205.761993), control1: CGPoint(x: 282.296509, y: 201.955017), control2: CGPoint(x: 281.732483, y: 203.647003))
            path.addCurve(to: CGPoint(x: 285.821503, y: 212.812012), control1: CGPoint(x: 281.732483, y: 207.171997), control2: CGPoint(x: 282.155518, y: 208.440979))
            path.addCurve(to: CGPoint(x: 293.576508, y: 228.321991), control1: CGPoint(x: 287.65448, y: 214.927002), control2: CGPoint(x: 289.346497, y: 217.324005))
            path.addLine(to: CGPoint(x: 296.114502, y: 244.255005))
            path.addCurve(to: CGPoint(x: 297.101501, y: 260.470001), control1: CGPoint(x: 296.678497, y: 249.753998), control2: CGPoint(x: 297.101501, y: 255.112))
            path.addCurve(to: CGPoint(x: 295.973511, y: 280.069), control1: CGPoint(x: 297.101501, y: 262.867004), control2: CGPoint(x: 296.96051, y: 265.687012))
            path.addCurve(to: CGPoint(x: 292.448486, y: 304.462006), control1: CGPoint(x: 295.550507, y: 284.016998), control2: CGPoint(x: 295.127502, y: 288.106018))
            path.addCurve(to: CGPoint(x: 285.680481, y: 323.214996), control1: CGPoint(x: 291.602478, y: 308.268982), control2: CGPoint(x: 290.615479, y: 311.794006))
            path.addCurve(to: CGPoint(x: 285.257507, y: 327.304016), control1: CGPoint(x: 285.398499, y: 324.484009), control2: CGPoint(x: 285.257507, y: 325.893982))
            path.addCurve(to: CGPoint(x: 289.346497, y: 332.380005), control1: CGPoint(x: 285.257507, y: 330.687988), control2: CGPoint(x: 286.526489, y: 332.380005))
            path.addCurve(to: CGPoint(x: 294.704498, y: 327.72699), control1: CGPoint(x: 290.051514, y: 332.380005), control2: CGPoint(x: 290.7565, y: 332.097992))
            path.addCurve(to: CGPoint(x: 300.344482, y: 314.049988), control1: CGPoint(x: 295.83252, y: 325.752991), control2: CGPoint(x: 296.819519, y: 323.497009))
            path.addCurve(to: CGPoint(x: 305.420502, y: 286.554993), control1: CGPoint(x: 301.0495, y: 311.653015), control2: CGPoint(x: 301.613495, y: 309.679016))
            path.addCurve(to: CGPoint(x: 306.548492, y: 264.841003), control1: CGPoint(x: 306.125488, y: 279.222992), control2: CGPoint(x: 306.548492, y: 272.031982))
            path.closeSubpath()
        }

        // MARK: Colon `:` — Eyes

        if drawColon {
            // Upper dot
            path.move(to: CGPoint(x: 264.8125, y: 256.945007))
            path.addCurve(to: CGPoint(x: 260.018494, y: 250.458984), control1: CGPoint(x: 264.8125, y: 256.098999), control2: CGPoint(x: 264.671509, y: 255.252991))
            path.addCurve(to: CGPoint(x: 249.725494, y: 251.869019), control1: CGPoint(x: 258.608521, y: 250.177002), control2: CGPoint(x: 256.916504, y: 249.894989))
            path.addCurve(to: CGPoint(x: 247.751495, y: 258.496002), control1: CGPoint(x: 248.033493, y: 253.278992), control2: CGPoint(x: 247.1875, y: 254.688995))
            path.addCurve(to: CGPoint(x: 253.391495, y: 262.584991), control1: CGPoint(x: 248.1745, y: 259.200989), control2: CGPoint(x: 248.879501, y: 259.906006))
            path.addCurve(to: CGPoint(x: 262.979492, y: 261.174988), control1: CGPoint(x: 254.378494, y: 263.148987), control2: CGPoint(x: 255.365494, y: 263.290009))
            path.addCurve(to: CGPoint(x: 264.8125, y: 256.945007), control1: CGPoint(x: 264.107483, y: 259.906006), control2: CGPoint(x: 264.8125, y: 258.496002))
            path.closeSubpath()

            // Lower dot
            path.move(to: CGPoint(x: 264.8125, y: 301.501007))
            path.addCurve(to: CGPoint(x: 260.018494, y: 295.015015), control1: CGPoint(x: 264.8125, y: 300.654999), control2: CGPoint(x: 264.671509, y: 299.80899))
            path.addCurve(to: CGPoint(x: 249.725494, y: 296.424988), control1: CGPoint(x: 258.608521, y: 294.733002), control2: CGPoint(x: 256.916504, y: 294.450989))
            path.addCurve(to: CGPoint(x: 247.751495, y: 303.052002), control1: CGPoint(x: 248.879501, y: 297.130005), control2: CGPoint(x: 248.315506, y: 297.834991))
            path.addCurve(to: CGPoint(x: 253.391495, y: 307.140991), control1: CGPoint(x: 248.1745, y: 303.757019), control2: CGPoint(x: 248.879501, y: 304.462006))
            path.addCurve(to: CGPoint(x: 262.979492, y: 305.872009), control1: CGPoint(x: 254.378494, y: 307.563995), control2: CGPoint(x: 255.365494, y: 307.846008))
            path.addCurve(to: CGPoint(x: 264.8125, y: 301.501007), control1: CGPoint(x: 264.107483, y: 304.602997), control2: CGPoint(x: 264.8125, y: 303.192993))
            path.closeSubpath()
        }

        // MARK: Left Arc `)` — Sad

        if drawLeft {
            path.move(to: CGPoint(x: 227.447495, y: 264.841003))
            path.addCurve(to: CGPoint(x: 226.460495, y: 247.92099), control1: CGPoint(x: 227.447495, y: 263.431), control2: CGPoint(x: 227.306503, y: 261.174988))
            path.addLine(to: CGPoint(x: 225.191498, y: 235.653992))
            path.addCurve(to: CGPoint(x: 220.538498, y: 213.234985), control1: CGPoint(x: 224.627502, y: 231.424011), control2: CGPoint(x: 223.922501, y: 227.194))
            path.addCurve(to: CGPoint(x: 213.629501, y: 200.403992), control1: CGPoint(x: 219.551498, y: 210.273987), control2: CGPoint(x: 218.423492, y: 207.735992))
            path.addCurve(to: CGPoint(x: 209.399506, y: 198.570984), control1: CGPoint(x: 212.219498, y: 199.276001), control2: CGPoint(x: 210.809494, y: 198.570984))
            path.addCurve(to: CGPoint(x: 204.464493, y: 200.544983), control1: CGPoint(x: 207.2845, y: 198.570984), control2: CGPoint(x: 205.592499, y: 199.276001))
            path.addCurve(to: CGPoint(x: 202.6315, y: 205.761993), control1: CGPoint(x: 203.195496, y: 201.955017), control2: CGPoint(x: 202.6315, y: 203.647003))
            path.addCurve(to: CGPoint(x: 206.720505, y: 212.812012), control1: CGPoint(x: 202.6315, y: 207.171997), control2: CGPoint(x: 203.054504, y: 208.440979))
            path.addCurve(to: CGPoint(x: 214.475494, y: 228.321991), control1: CGPoint(x: 208.553497, y: 214.927002), control2: CGPoint(x: 210.245499, y: 217.324005))
            path.addLine(to: CGPoint(x: 217.013504, y: 244.255005))
            path.addCurve(to: CGPoint(x: 218.000504, y: 260.470001), control1: CGPoint(x: 217.577499, y: 249.753998), control2: CGPoint(x: 218.000504, y: 255.112))
            path.addCurve(to: CGPoint(x: 216.872498, y: 280.069), control1: CGPoint(x: 218.000504, y: 262.867004), control2: CGPoint(x: 217.859497, y: 265.687012))
            path.addCurve(to: CGPoint(x: 213.347504, y: 304.462006), control1: CGPoint(x: 216.449493, y: 284.016998), control2: CGPoint(x: 216.026505, y: 288.106018))
            path.addCurve(to: CGPoint(x: 206.579498, y: 323.214996), control1: CGPoint(x: 212.501495, y: 308.268982), control2: CGPoint(x: 211.514496, y: 311.794006))
            path.addCurve(to: CGPoint(x: 206.156494, y: 327.304016), control1: CGPoint(x: 206.297501, y: 324.484009), control2: CGPoint(x: 206.156494, y: 325.893982))
            path.addCurve(to: CGPoint(x: 210.245499, y: 332.380005), control1: CGPoint(x: 206.156494, y: 330.687988), control2: CGPoint(x: 207.425507, y: 332.380005))
            path.addCurve(to: CGPoint(x: 215.6035, y: 327.72699), control1: CGPoint(x: 210.9505, y: 332.380005), control2: CGPoint(x: 211.655502, y: 332.097992))
            path.addCurve(to: CGPoint(x: 221.2435, y: 314.049988), control1: CGPoint(x: 216.731506, y: 325.752991), control2: CGPoint(x: 217.718506, y: 323.497009))
            path.addCurve(to: CGPoint(x: 226.319504, y: 286.554993), control1: CGPoint(x: 221.948502, y: 311.653015), control2: CGPoint(x: 222.512497, y: 309.679016))
            path.addCurve(to: CGPoint(x: 227.447495, y: 264.841003), control1: CGPoint(x: 227.024506, y: 279.222992), control2: CGPoint(x: 227.447495, y: 272.031982))
            path.closeSubpath()
        }

        // MARK: Normalize to Target Rect

        // Static union bounding box of ALL sub-paths. This MUST remain constant
        // regardless of which flags are active, so partial compositions align
        // spatially with the full logo.
        let fullBounds = CGRect(x: 202.6, y: 198.5, width: 104.0, height: 134.0)

        let scaleX = rect.width / fullBounds.width
        let scaleY = rect.height / fullBounds.height
        let scale = min(scaleX, scaleY)

        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: -fullBounds.minX, y: -fullBounds.minY)

        path = path.applying(transform)

        // Center the normalized path within the target rect
        let finalBounds = fullBounds.applying(transform)
        let shiftX = (rect.width - finalBounds.width) / 2.0
        let shiftY = (rect.height - finalBounds.height) / 2.0

        path = path.applying(CGAffineTransform(translationX: shiftX, y: shiftY))

        return path
    }
}
