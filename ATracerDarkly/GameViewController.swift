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
    var device: MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var computePipelineState: MTLComputePipelineState! = nil
    var bufferIndex = 0
    var curFrame: UInt32 = 0
    let inflightSemaphore = dispatch_semaphore_create(MaxBuffers)
    
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
    
    func loadAssets() {
        let view = self.view as! MTKView
        view.framebufferOnly = false
        
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        let raytracer = defaultLibrary.newFunctionWithName("raytrace")!
        
        let computePipelineDescriptor = MTLComputePipelineDescriptor()
        computePipelineDescriptor.label = "raytracer"
        computePipelineDescriptor.computeFunction = raytracer
        computePipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        do {
            computePipelineState = try device.newComputePipelineStateWithDescriptor(
                computePipelineDescriptor, options: .None, reflection: nil)
        } catch {
            print("Failed to create pipeline state, error \(error)")
        }
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
            let commandEncoder = commandBuffer.computeCommandEncoder()
            
            let outputTexture = currentDrawable.texture
            
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.label = "compute encoder"
            
            commandEncoder.setTexture(outputTexture, atIndex: 0)
            //commandEncoder.setTexture(outputTexture, atIndex: 1)
            // FIXME: Pass the scene graph in as an argument
//            commandEncoder.setBuffer(world, offset: 0, atIndex: 0)
            
            var frameInfo = FrameParameters(frameNumber: ++curFrame)
            let buffer: MTLBuffer = device.newBufferWithBytes(
                &frameInfo, length: sizeof(FrameParameters), options: .StorageModeShared)
            commandEncoder.setBuffer(buffer, offset: 0, atIndex: 0)
            
            let threadGroupCount = MTLSizeMake(8, 8, 1)
            let threadGroups = MTLSizeMake(
                outputTexture.width / threadGroupCount.width,
                outputTexture.height / threadGroupCount.height,
                1)
            
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            
            commandBuffer.presentDrawable(currentDrawable)
        }
        
        // bufferIndex matches the current semaphore controled frame index to ensure writing occurs
        // at the correct region in the vertex buffer
        bufferIndex = (bufferIndex + 1) % MaxBuffers
        
        commandBuffer.commit()
        
        timer.stop()
        if (timer.milliseconds > 1000.0/10.0) { print("Frame took \(timer.milliseconds)ms") }
    }
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
