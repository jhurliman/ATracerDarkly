//
//  Ray.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/23/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd

public struct Ray {
    public var origin: float3
    public var direction: float3
    
    public func pointAtParameter(t: Float) -> float3 {
        return origin + direction*t
    }
}
