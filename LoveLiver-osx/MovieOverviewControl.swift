//
//  MovieOverviewControl.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/03/15.
//  Copyright © 2016年 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import Ikemen
import NorthLayout


private let overviewHeight: CGFloat = 64


class MovieOverviewControl: NSView {
    let player: AVPlayer
    var playerTimeObserver: AnyObject?
    var currentTime: CMTime? {
        didSet { updateCurrentTime() }
    }
    private lazy var currentTimeBar: NSView = NSView(frame: NSZeroRect) ※ { v in
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.redColor().CGColor
        self.addSubview(v)
    }
    private lazy var currentTimeLabel: NSTextField = NSTextField(frame: NSZeroRect) ※ { tf in
        tf.bezeled = false
        tf.editable = false
        tf.drawsBackground = true
        tf.font = NSFont.monospacedDigitSystemFontOfSize(12, weight: NSFontWeightRegular)
        tf.textColor = NSColor.whiteColor()
        tf.backgroundColor = NSColor.blackColor()
    }

    var imageGenerator: AVAssetImageGenerator?
    var numberOfPages: UInt = 0 {
        didSet { setNeedsDisplayInRect(bounds) }
    }
    var thumbnails = [NSImage]()

    var startTime: CMTime? { didSet { reload() } }
    var endTime: CMTime? { didSet { reload() } }
    var scopedDuration: CMTime {
        guard let item = player.currentItem else { return kCMTimeZero }
        return CMTimeSubtract(endTime ?? item.duration, startTime ?? kCMTimeZero)
    }

    init(player: AVPlayer) {
        self.player = player
        
        super.init(frame: NSZeroRect)

        let autolayout = northLayoutFormat([:], [
            "currentTime": currentTimeLabel,
            ])
        autolayout("H:|[currentTime]")
        autolayout("V:[currentTime]|")

        setContentCompressionResistancePriority(NSLayoutPriorityDefaultHigh, forOrientation: .Vertical)
        setContentHuggingPriority(NSLayoutPriorityDefaultHigh, forOrientation: .Vertical)

        observePlayer()
        updateCurrentTime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        return CGSize(width: NSViewNoIntrinsicMetric, height: overviewHeight)
    }

    func reload() {
        imageGenerator?.cancelAllCGImageGeneration()
        imageGenerator = nil
        thumbnails.removeAll()

        guard let item = player.currentItem,
            let videoSize = item.naturalSize else {
                numberOfPages = 0
                return
        }

        // each page preserves aspect ratio of video and varies number of pages so that fill self.bounds.width
        let pageSize = NSSize(width: bounds.height / videoSize.height * videoSize.width, height: bounds.height)
        numberOfPages = UInt(ceil(bounds.width / pageSize.width))
        let times: [CMTime] = (0..<numberOfPages).map { i in
            CMTimeAdd(startTime ?? kCMTimeZero, CMTime(value: scopedDuration.value * Int64(i) / Int64(numberOfPages), timescale: scopedDuration.timescale))
        }

        // generate thumbnails for each page in background
        let generator = AVAssetImageGenerator(asset: item.asset) ※ {
            let scale = window?.backingScaleFactor ?? 1
            $0.maximumSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
        }
        imageGenerator = generator
        generator.generateCGImagesAsynchronouslyForTimes(times.map {NSValue(CMTime: $0)}) { (requestedTime, cgImage, actualTime, result, error) -> Void in
            guard let cgImage = cgImage where result == .Succeeded else { return }

            let thumb = NSImage(CGImage: cgImage, size: NSZeroSize)

            dispatch_async(dispatch_get_main_queue()) {
                guard self.imageGenerator === generator else { return } // avoid appending result from outdated requests
                self.thumbnails.append(thumb)
                self.setNeedsDisplayInRect(self.bounds)
            }
        }
    }

    func observePlayer() {
        if let playerTimeObserver = playerTimeObserver {
            player.removeTimeObserver(playerTimeObserver)
        }

        playerTimeObserver = player.addPeriodicTimeObserverForInterval(CMTime(value: 1, timescale: 30), queue: dispatch_get_main_queue()) { [weak self] time in
            self?.currentTime = time
        }
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()

        reload()
    }

    override var frame: NSRect {
        didSet { updateCurrentTime() }
    }

    private func updateCurrentTime() {
        if let time = currentTime {
            let p = CGFloat(CMTimeSubtract(time, startTime ?? kCMTimeZero).convertScale(scopedDuration.timescale, method: CMTimeRoundingMethod.Default).value)
                / CGFloat(scopedDuration.value)
            currentTimeBar.hidden = false
            currentTimeBar.frame = NSRect(x: p * bounds.width, y: 0, width: 1, height: bounds.height)
            currentTimeLabel.stringValue = time.stringInmmssSS
        } else {
            currentTimeBar.hidden = true
            currentTimeLabel.stringValue = "--:--.--"
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        NSColor.blackColor().setFill()
        NSRectFillUsingOperation(dirtyRect, .CompositeCopy)

        var x: CGFloat = 0
        for t in thumbnails {
            let pageRect = NSRect(x: x, y: 0, width: bounds.height / t.size.height * t.size.width, height: bounds.height)
            t.drawInRect(pageRect)
            x += pageRect.width
        }
    }

    override func mouseDown(theEvent: NSEvent) {
        seekToMousePosition(theEvent)
    }

    override func mouseDragged(theEvent: NSEvent) {
        seekToMousePosition(theEvent)
    }

    private func seekToMousePosition(theEvent: NSEvent) {
        let p = convertPoint(theEvent.locationInWindow, fromView: nil)
        let time = CMTimeAdd(CMTime(value: Int64(CGFloat(scopedDuration.value) * p.x / bounds.width), timescale: scopedDuration.timescale), startTime ?? kCMTimeZero)
        player.seekToTime(time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
}
