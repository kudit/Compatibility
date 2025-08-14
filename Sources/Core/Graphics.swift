//
//  Graphics.swift
//  Additions for CoreGraphics types
//
//  Created by Ben Ku on 7/17/24.
//

#if canImport(Foundation)
public extension CGSize {
    /// Swaps height and width of the CGSize.
    var transposed: CGSize {
        CGSize(width: height, height: width)
    }
}
#endif
