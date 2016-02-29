//
//  HitRecord.h
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#ifndef HitRecord_h
#define HitRecord_h

#include <metal_stdlib>

using namespace metal;

struct HitRecord {
    float t;
    float3 position;
    float3 normal;
    uint materialID;
    
    HitRecord():
        t(0),
        position(float3(0)),
        normal(float3(0)),
        materialID(0)
    {
    }
    
    HitRecord(float t, float3 position, float3 normal, uint materialID):
        t(t),
        position(position),
        normal(normal),
        materialID(materialID)
    {
    }
};

#endif /* HitRecord_h */
