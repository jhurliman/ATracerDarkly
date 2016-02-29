//
//  HitRecord.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd

public struct HitRecord {
    public var t: Float32
    public var position: float3
    public var normal: float3
    public var materialID: Int32
}
