//
//  RayProjector.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import simd

class RayProjector {
    static func getHits(rays: [Ray], world: World) -> [HitRecord] {
        var records = [HitRecord]()
        
        // FIXME:
        for ray in rays {
            if let rec = world.hit(ray, tmin: 0.0, tmax: FLT_MAX) {
                records.append(rec)
            }
        }
        
        return records
    }
}
