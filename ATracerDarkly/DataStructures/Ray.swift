//
//  Ray.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/23/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd

public class Ray {
    public var position: float3
    public var direction: float3
    
    init(position: float3, direction: float3) {
        self.position = position
        self.direction = direction
    }
    
    public func pointAtParameter(t: Float) -> float3 {
        return position + direction*t
    }
}
