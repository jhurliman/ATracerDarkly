//
//  Timer.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/24/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Darwin

struct Timer {
    static var base: UInt64 = 0
    var startTime: UInt64 = 0
    var stopTime: UInt64 = 0
    
    init() {
        if Timer.base == 0 {
            var info = mach_timebase_info(numer: 0, denom: 0)
            mach_timebase_info(&info)
            Timer.base = UInt64(info.numer / info.denom)
        }
    }
    
    mutating func start() {
        startTime = mach_absolute_time()
    }
    
    mutating func stop() {
        stopTime = mach_absolute_time()
    }
    
    var nanoseconds: UInt64 {
        return (stopTime - startTime) * Timer.base
    }
    
    var milliseconds: Double {
        return Double(nanoseconds) / 1_000_000.0
    }
    
    var seconds: Double {
        return Double(nanoseconds) / 1_000_000_000.0
    }
}
