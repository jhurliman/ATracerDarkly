//
//  Material.h
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#ifndef Material_h
#define Material_h

#include <metal_stdlib>

using namespace metal;

enum class MaterialType : uint16 {
    Lambertian = 0,
    Metal = 1
};

struct Material {
    uint materialID;
    MaterialType type;
    float3 albedo;
    float gloss;
    float reflectivity;
    float metalness;
    
    bool scatter(Ray ray, HitRecord rec, float3& attenuation, Ray& scattered) {
        return false; // FIXME:
    }
};

#endif /* Material_h */
