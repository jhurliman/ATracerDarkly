//
//  World.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Foundation

public class World : Hittable {
    var entities = [Hittable]()
    
    public func hit(ray: Ray, tmin: Float, var tmax: Float) -> HitRecord? {
        var closestRec: HitRecord? = nil
        
        for entity in entities {
            if let tempRec = entity.hit(ray, tmin: tmin, tmax: tmax) {
                tmax = tempRec.t
                closestRec = tempRec
            }
        }
        
        return closestRec
    }
}
