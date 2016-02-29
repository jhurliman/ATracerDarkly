//
//  Sphere.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd

public struct Sphere : Hittable {
    public var center: float3
    public var radius: Float32
    public var materialID: Int32
    
    public func hit(ray: Ray, tmin: Float, tmax: Float) -> HitRecord? {
        let oc = ray.origin - center
        let a = dot(ray.direction, ray.direction)
        let b = dot(oc, ray.direction)
        let c = dot(oc, oc) - radius*radius
        let discriminant = b*b - a*c
        if (discriminant <= 0) { return nil }
        let d = sqrt(b*b - a*c)
        
        var temp = (-b - d) / a
        if (temp < tmax && temp > tmin) {
            let p = ray.pointAtParameter(temp)
            return HitRecord(t: temp, position: p, normal: (p - center) * (1.0 / radius),
                materialID: 0)
        }
        
        temp = (-b + d) / a
        if (temp < tmax && temp > tmin) {
            let p = ray.pointAtParameter(temp)
            return HitRecord(t: temp, position: p, normal: (p - center) * (1.0 / radius),
                materialID: 0)
        }
        
        return nil
    }
}
