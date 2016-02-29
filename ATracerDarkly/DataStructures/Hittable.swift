//
//  Hittable.swift
//  ATracerDarkly
//
//  Created by John Hurliman on 2/25/16.
//  Copyright © 2016 John Hurliman. All rights reserved.
//

import Foundation

protocol Hittable {
    func hit(ray: Ray, tmin: Float, tmax: Float) -> HitRecord?
}
