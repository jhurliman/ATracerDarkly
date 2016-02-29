//
//  RayCollider.metal
//  ATracerDarkly
//
//  Created by John Hurliman on 2/26/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#include <metal_stdlib>
#include "Ray.h"
#include "Sphere.h"
#include "HitRecord.h"

using namespace metal;

kernel void collideRays(constant Ray* rays [[ buffer(0) ]],
                        constant Sphere* spheres [[ buffer(1) ]],
                        constant int& sphereCount [[ buffer(2) ]],
                        device HitRecord* hits [[ buffer(3) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    uint2 size = uint2(800, 400);
    
    Ray ray = rays[gid.y*size.x + gid.x];
    HitRecord tempRec;
    float closestSoFar = FLT_MAX;
    HitRecord closestRec = HitRecord();
    
    for (int i = 0; i < sphereCount; i++) {
        Sphere sphere = spheres[i];
        sphere.hit(ray, 0.0, closestSoFar, closestRec);
    }
    
    hits[gid.y*size.x + gid.x] = closestRec;
}
