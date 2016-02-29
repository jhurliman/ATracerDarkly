//
//  MemoryManager.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import MetalKit

let METAL_ALIGNMENT = 0x1000 // 4096 byte alignment required by Metal

class DeviceSharedArray<T> {
    let buffer: MTLBuffer
    let pointer: UnsafeMutableBufferPointer<T>
    
    init(type: T, count: Int, device: MTLDevice) {
        (buffer, pointer) = MemoryManager.createSharedArray(device, count: count)
    }
    
    init(fromArray: [T], device: MTLDevice) {
        (buffer, pointer) = MemoryManager.createSharedArray(device, count: fromArray.count)
        MemoryManager.copyArrayToBuffer(fromArray, buffer: buffer)
    }
    
    subscript(index: Int) -> T {
        get { return pointer[index] }
        set { pointer[index] = newValue }
    }
}

class MemoryManager {
    static func copyStructToDevice<T>(var obj: T, device: MTLDevice) -> MTLBuffer {
        let length = sizeof(T)
        return device.newBufferWithBytes(&obj, length: length, options: .StorageModeShared)
        
//        let buffer = device.newBufferWithLength(sizeof(T), options: .StorageModeManaged)
//        copyStructToBuffer(obj, buffer: buffer)
//        return buffer
    }
    
    static func copyStructToBuffer<T>(var obj: T, buffer: MTLBuffer) {
        withUnsafeMutablePointer(&obj) { ptr in
            memcpy(buffer.contents(), ptr, sizeof(T))
        }
    }
    
    static func readStructFromDevice<T>(buffer: MTLBuffer) -> T {
        let typedPtr = UnsafeMutablePointer<T>(buffer.contents())
        return typedPtr.move()
    }
    
    static func copyArrayToDevice<T>(array: [T], device: MTLDevice) -> MTLBuffer {
        let buffer = device.newBufferWithLength(array.count * sizeof(T), options: .StorageModeManaged)
        copyArrayToBuffer(array, buffer: buffer)
        return buffer
    }
    
    static func copyArrayToBuffer<T>(var array: [T], buffer: MTLBuffer) {
        // Get a pointer to the array
        let bufferPtr = array.withUnsafeMutableBufferPointer {
            (inout ptr: UnsafeMutableBufferPointer<T>) -> UnsafeMutableBufferPointer<T>! in
            return ptr
        }
        
        // Copy data from the array to aligned memory
        memcpy(buffer.contents(), bufferPtr.baseAddress, array.count * sizeof(T))
    }
    
    static func readArrayFromDevice<T>(buffer: MTLBuffer, count: Int) -> [T] {
        let typedPtr = UnsafeMutablePointer<T>(buffer.contents())
        let bufferPtr = UnsafeMutableBufferPointer<T>(start: typedPtr, count: count)
        
        // TODO: Should we just return the UnsafeMutableBufferPointer<T>?
        var array = [T]()
        for index in bufferPtr.startIndex..<bufferPtr.endIndex {
            array.append(bufferPtr[index])
        }
        
        return array
    }
    
    static func createSharedArray<T>(device: MTLDevice, count: Int) ->
        (MTLBuffer, UnsafeMutableBufferPointer<T>)
    {
        let dataSize = count * sizeof(T)
        
        // Allocate a new aligned block of memory
        let alignedSize = byteSizeWithAlignment(METAL_ALIGNMENT,
            size: dataSize)
        var alignedMemory: UnsafeMutablePointer<Void> = nil
        posix_memalign(&alignedMemory, METAL_ALIGNMENT, alignedSize)
        
        // Initialize the aligned block
        memset(alignedMemory, 0, alignedSize)
        
        // Create an MTLBuffer for the aligned block (GPU)
        let buffer = device.newBufferWithBytesNoCopy(alignedMemory,
            length: alignedSize, options: .StorageModeShared, deallocator: nil)
        
        // Create a pointer for the aligned block (CPU)
        let typedPtr = UnsafeMutablePointer<T>(alignedMemory)
        let bufferPtr = UnsafeMutableBufferPointer<T>(start: typedPtr, count: count)
        
        return (buffer, bufferPtr)
    }
    
    private static func byteSizeWithAlignment(alignment: Int, size: Int) -> Int {
        return Int(ceil(Float(size) / Float(alignment))) * alignment
    }
}
