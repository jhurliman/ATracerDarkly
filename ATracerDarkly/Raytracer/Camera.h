//
//  Camera.h
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#ifndef Camera_h
#define Camera_h

#include <metal_stdlib>
#include "Ray.h"

using namespace metal;

struct Camera {
    packed_float3 origin;
    packed_float3 lowerLeftCorner;
    packed_float3 horizontal;
    packed_float3 vertical;
    
    static Ray getRay(const Camera cam, float2 uv) {
        return Ray(cam.origin, cam.lowerLeftCorner + uv.x*cam.horizontal + uv.y*cam.vertical);
    }
};

#endif /* Camera_h */
