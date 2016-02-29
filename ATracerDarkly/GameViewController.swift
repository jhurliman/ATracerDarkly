//
//  GameViewController.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/23/16.
//  Copyright (c) 2016 John Hurliman. All rights reserved.
//

import Cocoa
import MetalKit
import simd

let MaxBuffers = 3

struct FrameParameters {
    var frameNumber: UInt32
}

class GameViewController: NSViewController, MTKViewDelegate {
    let world = World()
    
    var device: MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var bufferIndex = 0
    var curFrame: UInt32 = 0
    let inflightSemaphore = dispatch_semaphore_create(MaxBuffers)
    
    var cameraBuffer: MTLBuffer? = nil
    var rays: DeviceSharedArray<Ray>! = nil
    var spheres: DeviceSharedArray<Sphere>! = nil
    var hits: DeviceSharedArray<HitRecord>! = nil
//    var rayBuffer: MTLBuffer! = nil
//    var rayPointer: UnsafeMutableBufferPointer<Ray>! = nil
    
    var createRaysState: MTLComputePipelineState! = nil
    var createHitsState: MTLComputePipelineState! = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            self.view = NSView(frame: self.view.frame)
            return
        }
        
        // Setup view properties
        let view = self.view as! MTKView
        view.delegate = self
        view.device = device
        
        loadAssets()
    }
    
    func createComputeState(library: MTLLibrary, functionName: String) -> MTLComputePipelineState {
        let function = library.newFunctionWithName(functionName)!
        
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.label = functionName
        descriptor.computeFunction = function
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        return try! device.newComputePipelineStateWithDescriptor(
            descriptor, options: .None, reflection: nil)
    }
    
    func loadAssets() {
        let view = self.view as! MTKView
        view.framebufferOnly = false
        
        commandQueue = device.newCommandQueue()
        commandQueue.label = "Main Command Queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        
        createRaysState = createComputeState(defaultLibrary, functionName: "createRays")
        createHitsState = createComputeState(defaultLibrary, functionName: "collideRays")
        
        cameraBuffer = MemoryManager.copyStructToDevice(Camera(), device: device)
        
        let ray = Ray(origin: float3(), direction: float3())
        rays = DeviceSharedArray(type: ray.self, count: 800 * 400, device: device)
        
//        Sphere(float3(0, 0, -1), 0.5, Material(false, float3(0.8, 0.3, 0.3))),
        ////        Sphere(float3(0, -100.5, -1), 100, Material(false, float3(0.8, 0.8, 0.3))),
        ////        Sphere(float3(1, 0, -1), 0.5, Material(true, float3(0.8, 0.6, 0.2))),
        ////        Sphere(float3(-1, 0, -1), 0.5, Material(true, float3(0.8, 0.8, 0.8)))
        
        world.entities.append(Sphere(center: float3(0, 0, -1), radius: 0.5, materialID: 0))
        world.entities.append(Sphere(center: float3(0, -100.5, -1), radius: 100, materialID: 0))
        world.entities.append(Sphere(center: float3(1, 0, -1), radius: 0.5, materialID: 0))
        world.entities.append(Sphere(center: float3(-1, 0, -1), radius: 0.5, materialID: 0))
    }
    
    func createRays(commandBuffer: MTLCommandBuffer, outputTexture: MTLTexture) -> DeviceSharedArray<Ray> {
        let encoder = commandBuffer.computeCommandEncoder()
        
        encoder.setComputePipelineState(createRaysState)
        encoder.label = "Create Rays"
        
        encoder.setBuffer(cameraBuffer, offset: 0, atIndex: 0)
        encoder.setBuffer(rays.buffer, offset: 0, atIndex: 1)
        
        let threadGroupCount = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake(
            outputTexture.width / threadGroupCount.width,
            outputTexture.height / threadGroupCount.height,
            1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return rays
    }
    
    func createHits(commandBuffer: MTLCommandBuffer, rays: DeviceSharedArray<Ray>, outputTexture: MTLTexture) -> DeviceSharedArray<HitRecord> {
        let encoder = commandBuffer.computeCommandEncoder()
        
        encoder.setComputePipelineState(createHitsState)
        encoder.label = "Create Hits"
        
        var sphereCount = spheres.pointer.count
        
        encoder.setBuffer(rays.buffer, offset: 0, atIndex: 0)
        encoder.setBuffer(spheres.buffer, offset: 0, atIndex: 1)
        withUnsafePointer(&sphereCount) { encoder.setBytes($0, length: sizeof(Int32), atIndex: 2) }
        encoder.setBuffer(hits.buffer, offset: 0, atIndex: 3)
        
        let threadGroupCount = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake(
            outputTexture.width / threadGroupCount.width,
            outputTexture.height / threadGroupCount.height,
            1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return hits
    }
    
    func drawInMTKView(view: MTKView) {
        // use semaphore to encode 3 frames ahead
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        var timer = Timer()
        timer.start()
        
//        self.update()
        
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        // use completion handler to signal the semaphore when this frame is completed allowing the
        // encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere
        // besides this stack frame
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                dispatch_semaphore_signal(strongSelf.inflightSemaphore)
            }
        }
        
        if let currentDrawable = view.currentDrawable {
            let outputTexture = currentDrawable.texture
            
            let rays = createRays(commandBuffer, outputTexture: outputTexture)
            let hits = createHits(commandBuffer, rays: rays, outputTexture: outputTexture)
            
            print(hits.pointer[0])
        }
        
//        if let currentDrawable = view.currentDrawable {
//            let commandEncoder = commandBuffer.computeCommandEncoder()
//            
//            let outputTexture = currentDrawable.texture
//            
//            commandEncoder.setComputePipelineState(computePipelineState)
//            commandEncoder.label = "compute encoder"
//            
//            commandEncoder.setTexture(outputTexture, atIndex: 0)
//            //commandEncoder.setTexture(outputTexture, atIndex: 1)
//            // FIXME: Pass the scene graph in as an argument
////            commandEncoder.setBuffer(world, offset: 0, atIndex: 0)
//            
//            var frameInfo = FrameParameters(frameNumber: ++curFrame)
//            let buffer: MTLBuffer = device.newBufferWithBytes(
//                &frameInfo, length: sizeof(FrameParameters), options: .StorageModeShared)
//            commandEncoder.setBuffer(buffer, offset: 0, atIndex: 0)
//            
//            let threadGroupCount = MTLSizeMake(8, 8, 1)
//            let threadGroups = MTLSizeMake(
//                outputTexture.width / threadGroupCount.width,
//                outputTexture.height / threadGroupCount.height,
//                1)
//            
//            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
//            commandEncoder.endEncoding()
//            
//            commandBuffer.presentDrawable(currentDrawable)
//        }
        
        // bufferIndex matches the current semaphore controled frame index to ensure writing occurs
        // at the correct region in the vertex buffer
        bufferIndex = (bufferIndex + 1) % MaxBuffers
        
        
        
        timer.stop()
        if (timer.milliseconds > 1000.0/10.0) { print("Frame took \(timer.milliseconds)ms") }
    }
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
