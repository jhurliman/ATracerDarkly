//
//  RayScheduler.metal
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#include <metal_stdlib>
#include "Camera.h"

using namespace metal;

static float rand(uint3 seed)
{
    int s = seed.x + seed.y * 57 + seed.z * 241;
    s = (s << 13) ^ s;
    return ((1.0 - ((s*(s*s*15731 + 789221) + 1376312589) & 2147483647)/1073741824.0f) + 1.0f)/2.0f;
}

kernel void createRays(constant Camera &camera [[ buffer(0) ]],
                       device Ray* out [[ buffer(1) ]],
                       uint2 gid [[ thread_position_in_grid ]])
{
    uint3 seed1 = uint3(gid.x, gid.y, 1);
    uint3 seed2 = uint3(gid.x, gid.y, 2);
    uint2 size = uint2(800, 400);
    
    float2 uv = float2(((float)gid.x + rand(seed1)) / size.x,
                 1.0 - ((float)gid.y + rand(seed2)) / size.y);
    Ray ray = Camera::getRay(camera, uv);
    
    out[gid.y*size.x + gid.x] = ray;
}
