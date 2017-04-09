//
//  Shaders.metal
//  ATracerDarkly
//
//  Created by John Hurliman on 2/23/16.
//  Copyright (c) 2016 John Hurliman. All rights reserved.
//

#include <metal_stdlib>

#define M_PI 3.14159265358979323846	/* pi */

using namespace metal;

static float3 randInUnitSphere(thread int3& seed);

struct Material;

struct FrameParameters {
    uint frameNumber;
};

struct Ray {
    float3 origin;
    float3 direction;
    
    Ray(float3 origin, float3 direction) {
        this->origin = origin;
        this->direction = direction;
    }
    
    float3 pointAtParameter(float t) {
        return origin + direction*t;
    }
};

struct Camera {
    float3 origin;
    float3 lowerLeftCorner;
    float3 horizontal;
    float3 vertical;
    
    Camera() {
        origin = float3(0, 0, 0);
        lowerLeftCorner = float3(-2, -1, -1);
        horizontal = float3(4, 0, 0);
        vertical = float3(0, 2, 0);
    }
    
    Ray getRay(float2 uv) {
        return Ray(origin, lowerLeftCorner + uv.x*horizontal + uv.y*vertical);
    }
};

struct HitRecord {
    float t;
    float3 position;
    float3 normal;
    float3 attenuation;
    thread Material* materialPtr;
    
    HitRecord():
        t(0),
        position(float3(0)),
        normal(float3(0)),
        attenuation(float3(1)),
        materialPtr(nullptr)
    {
    }
    
    HitRecord(float t, float3 position, float3 normal, thread Material* materialPtr):
        t(t),
        position(position),
        normal(normal),
        attenuation(float3(1)),
        materialPtr(materialPtr)
    {
    }
};

struct Material {
    bool metallic;
    float3 albedo;
    
    Material(bool metallic, float3 albedo):
        metallic(metallic),
        albedo(albedo)
    {
    }
    
    bool scatter(thread const Ray& ray, thread HitRecord& rec,
                 thread Ray& scattered, thread int3& seed)
    {
        if (metallic) return scatterMetal(ray, rec, scattered, seed);
        else return scatterLambertian(ray, rec, scattered, seed);
    }
    
    bool scatterLambertian(thread const Ray& ray, thread HitRecord& rec,
                           thread Ray& scattered, thread int3& seed)
    {
        float3 target = rec.position + rec.normal + randInUnitSphere(seed);
        scattered = Ray(rec.position, target - rec.position);
        rec.attenuation = albedo;
        return true;
    }
    
    bool scatterMetal(thread const Ray& ray, thread HitRecord& rec,
                      thread Ray& scattered, thread int3& seed)
    {
        scattered = Ray(rec.position, reflect(normalize(ray.direction), rec.normal));
        rec.attenuation = albedo;
        return dot(scattered.direction, rec.normal) > 0.0;
    }
};

struct Sphere {
    float3 center;
    float radius;
    Material material;
    
    Sphere(float3 center, float radius, Material material):
        center(center),
        radius(radius),
        material(material)
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
            rec = HitRecord(temp, p, (p - center) / radius, &material);
            return true;
        }
        
        temp = (-b + d) / a;
        if (temp < tmax && temp > tmin) {
            float3 p = ray.pointAtParameter(temp);
            rec = HitRecord(temp, p, (p - center) / radius, &material);
            return true;
        }
        
        return false;
    }
};

struct SphereList {
    Sphere spheres[4] = {
        Sphere(float3(0, 0, -1), 0.5, Material(false, float3(0.8, 0.3, 0.3))),
        Sphere(float3(0, -100.5, -1), 100, Material(false, float3(0.8, 0.8, 0.3))),
        Sphere(float3(1, 0, -1), 0.5, Material(true, float3(0.8, 0.6, 0.2))),
        Sphere(float3(-1, 0, -1), 0.5, Material(true, float3(0.8, 0.8, 0.8)))
    };
    int count;
    
    SphereList(int count):
        count(count)
    {
    }
    
    bool hit(Ray ray, float tmin, float tmax, thread HitRecord& rec) {
        HitRecord tempRec;
        bool hitAnything = false;
        float closestSoFar = tmax;
        
        for (int i = 0; i < count; i++) {
            Sphere& sphere = spheres[i];
            if (sphere.hit(ray, tmin, closestSoFar, tempRec)) {
                hitAnything = true;
                closestSoFar = tempRec.t;
                rec = tempRec;
            }
        }
        
        return hitAnything;
    }
};

static float rand(thread int3& x)
{
    int seed = x.x + x.y * 57 + x.z * 241;
    seed = (seed << 13) ^ seed;
    float val = (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
    
    x ^= seed;
    x.z *= -1;
    
    return val;
}

static float3 randInUnitSphere(thread int3& seed)
{
    const int MAX_TRIES = 10;
    float3 p;
    float dotP;
    int i = 0;
    do {
        p = 2.0 * float3(rand(seed), rand(seed), rand(seed)) - 1.0;
        dotP = dot(p, p);
    } while (dotP >= 1.0 && i++ < MAX_TRIES);
    return dotP >= 1.0 ? float3(0) : p;
}

static float3 color(Ray ray, SphereList world, thread int3& seed)
{
    const int MAX_HITS = 3;
    
    HitRecord stack[MAX_HITS];
    int hitIndex = 0;
    float3 c = float3(0);
    
    // Build a list of all of the hits as the ray bounces through the world
    while (hitIndex < MAX_HITS) {
        if (world.hit(ray, 0.001, FLT_MAX, stack[hitIndex])) {
            // DEBUG: render normals
            //c = 0.5 * (stack[hitIndex].normal + 1.0); break;
            
            if (stack[hitIndex].materialPtr->scatter(ray, stack[hitIndex], ray, seed)) {
                hitIndex++;
            } else {
                break;
            }
        } else {
            float3 normDir = normalize(ray.direction);
            float t = 0.5*(normDir.y + 1.0);
            c = (1.0 - t)*float3(1.0, 1.0, 1.0) + t*float3(0.5, 0.7, 1.0);
            
            break;
        }
    }
    
    // Work backwards from where the bounce ended to the origin, applying materials to the output
    for (int i = hitIndex - 1; i >= 0; i--) {
        HitRecord rec = stack[i];
        c *= rec.attenuation;
    }
    
    // DEBUG: Count hits by tinting pixels
//    if (hitIndex < 1) c *= float3(1, 0, 0);
//    else if (hitIndex < 2) c *= float3(0, 1, 0);
//    else if (hitIndex < 3) c *= float3(0, 0, 1);
    
    return c;
}

kernel void raytrace(/*texture2d<float, access::read> inTexture [[ texture(0) ]],*/
                     texture2d<float, access::write> outTexture [[ texture(0) ]],
                     constant FrameParameters &frameInfo [[buffer(0)]],
                     uint2 gid [[ thread_position_in_grid ]])
{
    const int NUM_SAMPLES = 1;
    
    SphereList world = SphereList(4);
    Camera camera;
    float2 outputSize = float2(outTexture.get_width(), outTexture.get_height());
    thread int3 seed = int3(gid.x, gid.y, frameInfo.frameNumber);
    
    float3 c = float3(0);
    for (int i = 0; i < NUM_SAMPLES; i++) {
        float2 uv = float2(((float)gid.x + rand(seed)) / outputSize.x,
                     1.0 - ((float)gid.y + rand(seed)) / outputSize.y);
        
        Ray ray = camera.getRay(uv);
        c += color(ray, world, seed);
    }
    c /= NUM_SAMPLES;
    
    // NOTE: Started on progressive updates, needs better support in the host app
//    float4 curColor = inTexture.read(gid);
//    float pct = 1.0/(float)frameInfo.frameNumber;
//    outTexture.write((1.0-pct)*curColor + pct*float4(c, 1.0), gid);
    
    outTexture.write(float4(c, 1.0), gid);
}
