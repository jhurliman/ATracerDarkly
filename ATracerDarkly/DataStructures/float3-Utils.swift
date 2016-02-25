//
//  float3-Utils.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/23/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd


extension float3 {
    func length() -> Float {
        return sqrt(x*x + y*y + z*z)
    }
    
    func lengthSquared() -> Float {
        return x*x + y*y + z*z
    }
    
    func unitVector() -> float3 {
        let ooLen: Float = 1.0 / length()
        return self * ooLen
    }
    
    static let One = float3(1, 1, 1)
    static let Zero = float3()
}
