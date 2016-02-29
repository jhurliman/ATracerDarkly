//
//  Camera.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import MetalKit

public struct Camera {
    public var origin: float3
    public var lowerLeftCorner: float3
    public var horizontal: float3
    public var vertical: float3
    
    init() {
        origin = float3(0, 0, 0);
        lowerLeftCorner = float3(-2, -1, -1)
        horizontal = float3(4, 0, 0)
        vertical = float3(0, 2, 0)
    }
    
    public func getRay(uv: float2) -> Ray {
        return Ray(origin: origin, direction: lowerLeftCorner + uv.x*horizontal + uv.y*vertical)
    }
}
