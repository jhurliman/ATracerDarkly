//
//  Ray.h
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#ifndef Ray_h
#define Ray_h

#include <metal_stdlib>

using namespace metal;

struct Ray {
    float3 origin;
    float3 direction;
    
    Ray(float3 origin, float3 direction):
        origin(origin),
        direction(direction)
    {
    }
    
    float3 pointAtParameter(float t) {
        return origin + direction*t;
    }
};

#endif /* Ray_h */
