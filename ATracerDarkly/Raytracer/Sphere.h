//
//  Sphere.h
//  ATracerDarkly
//
//  Created by John Hurliman on 2/26/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#ifndef Sphere_h
#define Sphere_h

#include <metal_stdlib>
#include "Ray.h"
#include "HitRecord.h"

using namespace metal;

struct Sphere {
    float3 center;
    float radius;
    uint materialID;
    
    Sphere(float3 center, float radius, uint materialID):
        center(center),
        radius(radius),
        materialID(materialID)
    {
    }
    
    bool hit(Ray ray, float tmin, float tmax, thread HitRecord& rec) {
        float3 oc = ray.origin - center;
        float a = dot(ray.direction, ray.direction);
        float b = dot(oc, ray.direction);
        float c = dot(oc, oc) - radius*radius;
        float discriminant = b*b - a*c;
        if (discriminant <= 0) { return false; }

        float d = sqrt(b*b - a*c);
        float temp = (-b - d) / a;
        if (temp < tmax && temp > tmin) {
            float3 p = ray.pointAtParameter(temp);
            rec = HitRecord(temp, p, (p - center) / radius, materialID);
            return true;
        }

        temp = (-b + d) / a;
        if (temp < tmax && temp > tmin) {
            float3 p = ray.pointAtParameter(temp);
            rec = HitRecord(temp, p, (p - center) / radius, materialID);
            return true;
        }
        
        return false;
    }
};

#endif /* Sphere_h */
