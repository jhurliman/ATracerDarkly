//
//  Ray.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/23/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd

open class Ray {
    open var position: float3
    open var direction: float3
    
    init(position: float3, direction: float3) {
        self.position = position
        self.direction = direction
    }
    
    open func pointAtParameter(_ t: Float) -> float3 {
        return position + direction*t
    }
}
