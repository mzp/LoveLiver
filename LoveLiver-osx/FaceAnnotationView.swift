//
//  FaceAnnotationView.swift
//  LoveLiver
//
//  Created by BAN Jun on 5/4/16.
//  Copyright © 2016 mzp. All rights reserved.
//

import AppKit
import AVFoundation


struct DetectedFace {
    /// time detected
    let at: CMTime
    /// detected face bounds in original video resolution
    let rect: CGRect

    var size: CGFloat {
        return rect.width * rect.height
    }
}


class FaceAnnotationView: NSView {
    var duration = kCMTimeZero
    // at: time percent in video length, size: area size of face
    var faces = [DetectedFace]() {
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

        path.moveToPoint(.zero)
        let points: [CGPoint] = 0.stride(to: Int(bounds.width), by: 4).map { x in
            let s = faces.filter({abs(CGFloat($0.at.seconds / duration.seconds) * bounds.width - CGFloat(x)) <= 4}).reduce(0) {$0 + $1.size}
            return CGPoint(x: CGFloat(x), y: s)
        }
        let maxSize = points.maxElement {$0.y < $1.y}?.y ?? 0
        for p in points {
            path.lineToPoint(NSPoint(x: p.x, y: p.y * bounds.height / maxSize))
        }
        path.lineToPoint(NSPoint(x: bounds.width, y: 0))
        
        NSColor.greenColor().colorWithAlphaComponent(0.75).set()
        path.fill()
        NSColor.greenColor().set()
        path.stroke()
    }
}
