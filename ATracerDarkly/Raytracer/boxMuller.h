//
//  boxMuller.h
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

#ifndef boxMuller_h
#define boxMuller_h

static uint TausStep(thread uint &z, int S1, int S2, int S3, uint M)
{
    uint b = (((z << S1) ^ z) >> S2);
    z = (((z & M) << S3) ^ b);
    return z;
}

// A and C are constants
static uint LCGStep(thread uint &z, uint A, uint C)
{
    z = (A * z + C);
    return z;
}

static float HybridTaus(thread int3& x)
{
    thread uint z[4] = { (uint)x.x, (uint)x.y, (uint)x.z, (uint)(x.x ^ x.y ^ x.z) };
    
    // Combined period is lcm(p1,p2,p3,p4)~ 2^121
    float val = 2.3283064365387e-10 * (             // Periods
        TausStep(z[0], 13, 19, 12, 4294967294UL) ^  // p1=2^31-1
        TausStep(z[1], 2, 25, 4, 4294967288UL)   ^  // p2=2^30-1
        TausStep(z[2], 3, 11, 17, 4294967280UL)  ^  // p3=2^28-1
        LCGStep(z[3], 1664525, 1013904223UL)        // p4=2^32
    );
    
    x.x = z[0] ^ z[3];
    x.y = z[1] ^ z[3];
    x.z = z[2] ^ z[3];
    
    return val;
}

float2 boxMuller(thread int3& x)
{
    float u0 = HybridTaus(x), u1 = HybridTaus(x);
    float r = sqrt(-2 * log(u0));
    float theta = 2 * M_PI * u1;
    return float2(r * sin(theta), r * cos(theta));
}

#endif /* boxMuller_h */
