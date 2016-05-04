//
//  FaceAnnotationView.swift
//  LoveLiver
//
//  Created by BAN Jun on 5/4/16.
//  Copyright © 2016 mzp. All rights reserved.
//

import AppKit


class FaceAnnotationView: NSView {
    // at: time percent in video length, size: area size of face
    var faces = [(at: CGFloat, size: CGFloat)]() {
        didSet {
            setNeedsDisplayInRect(bounds)
        }
    }
    
    override var opaque: Bool {return false}
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor.clearColor().set()
        NSRectFillUsingOperation(dirtyRect, .CompositeSourceOver)
        guard !faces.isEmpty else { return }
        
        let path = NSBezierPath()
        
        let maxSize = faces.maxElement {$0.size < $1.size}?.size ?? 0
        path.moveToPoint(.zero)
        for x in 0.stride(to: Int(bounds.width), by: 4) {
            let s = faces.filter({abs($0.at * bounds.width - CGFloat(x)) <= 4}).maxElement {$0.size < $1.size}?.size ?? 0
            path.lineToPoint(NSPoint(x: CGFloat(x), y: bounds.height * (s / maxSize)))
        }
        path.lineToPoint(NSPoint(x: bounds.width, y: 0))
        
        NSColor.redColor().colorWithAlphaComponent(0.75).set()
        path.fill()
        NSColor.redColor().set()
        path.stroke()
    }
}
