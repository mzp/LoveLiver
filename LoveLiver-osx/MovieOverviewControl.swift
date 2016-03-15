//
//  MovieOverviewControl.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/03/15.
//  Copyright © 2016年 mzp. All rights reserved.
//

import Cocoa
import AVFoundation


private let overviewHeight: CGFloat = 64


class MovieOverviewControl: NSView {
    var player: AVPlayer? {
        didSet { reload() }
    }
    var numberOfPages: UInt = 0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    var thumbnails = [NSImage]()

    init(player: AVPlayer) {
        self.player = player
        
        super.init(frame: NSZeroRect)

        setContentCompressionResistancePriority(NSLayoutPriorityDefaultHigh, forOrientation: .Vertical)
        setContentHuggingPriority(NSLayoutPriorityDefaultHigh, forOrientation: .Vertical)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        return nil
    }

    override var intrinsicContentSize: NSSize {
        return CGSize(width: NSViewNoIntrinsicMetric, height: overviewHeight)
    }

    func reload() {
        thumbnails.removeAll()
        guard let item = player?.currentItem,
            let track = item.asset.tracksWithMediaType(AVMediaTypeVideo).first else {
                numberOfPages = 0
                return
        }

        let thumbSize = NSSize(width: bounds.height / track.naturalSize.height * track.naturalSize.width, height: bounds.height)
        numberOfPages = UInt(ceil(bounds.width / thumbSize.width))
        let duration = item.duration

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let generator = AVAssetImageGenerator(asset: item.asset)
            for i in 0..<self.numberOfPages {
                let thumb = NSImage(size: thumbSize)
                thumb.lockFocus()
                let frameImage = generator.copyImage(at: CMTime(value: duration.value * Int64(i) / Int64(self.numberOfPages), timescale: duration.timescale))
                frameImage?.drawInRect(NSRect(origin: CGPointZero, size: NSSizeToCGSize(thumbSize)))
                thumb.unlockFocus()
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.thumbnails.append(thumb)
                    self.setNeedsDisplayInRect(self.bounds)
                }
            }
        }
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()

        reload()
    }

    override func drawRect(dirtyRect: NSRect) {
        NSColor.blackColor().setFill()
        NSRectFillUsingOperation(dirtyRect, .CompositeCopy)

        let cellWidth = bounds.width / CGFloat(numberOfPages)
        for (i, t) in thumbnails.enumerate() {
            let pageRect = NSRect(x: CGFloat(i) * cellWidth, y: 0, width: cellWidth, height: bounds.height)
            t.drawInRect(pageRect)
        }
    }
}
