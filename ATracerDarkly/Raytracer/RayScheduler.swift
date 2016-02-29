//
//  RayScheduler.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import MetalKit

public class RayScheduler {
    // FIXME: Given a Camera, build an MTLBuffer of RayAndTexCoords
    
    public func updateRays(camera: Camera, frame: uint, rays: MTLBuffer) {
        // FIXME: Build a list of all drawable pixels, create slightly randomized rays that pass
        // through those pixels, write those rays to a buffer
        
        
        
        // FIXME: Add maximum number of antialiasing passes
        
        // TODO: Move this logic to GPU
    }
}
