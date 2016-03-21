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
    var imageGeneratorTolerance = CMTime(seconds: 300, preferredTimescale: 600)

    // overview control supports timmed playback and scope edit
    var trimRange: CMTimeRange { didSet { reload() } } // show overview only within trimRange
    var scopeRange: CMTimeRange? { // if non-nil, shows scope control
        didSet { updateScope() }
    }
    private lazy var scopeMaskLeftView: NSView = NSView(frame: NSZeroRect) ※ { v in
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(white: 0, alpha: 0.75).CGColor
        v.hidden = true
    }
    private lazy var scopeMaskRightView: NSView = NSView(frame: NSZeroRect) ※ { v in
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(white: 0, alpha: 0.75).CGColor
        v.hidden = true
    }

    init(player: AVPlayer, playerItem: AVPlayerItem) {
        self.player = player
        self.trimRange = CMTimeRange(start: kCMTimeZero, duration: playerItem.duration)
        
        super.init(frame: NSZeroRect)

        let autolayout = northLayoutFormat([:], [
            "currentTime": currentTimeLabel,
            ])
        autolayout("H:|[currentTime]")
        autolayout("V:[currentTime]|")

        setContentCompressionResistancePriority(NSLayoutPriorityDefaultHigh, forOrientation: .Vertical)
        setContentHuggingPriority(NSLayoutPriorityDefaultHigh, forOrientation: .Vertical)

        // subviews ordering
        addSubview(scopeMaskLeftView)
        addSubview(scopeMaskRightView)
        sortSubviewsUsingFunction({ (v1, v2, context) -> NSComparisonResult in
            let s = Unmanaged<MovieOverviewControl>.fromOpaque(COpaquePointer(context)).takeUnretainedValue()
            switch (v1, v2) {
            case (s.currentTimeLabel, _): return .OrderedDescending
            default: return .OrderedSame
            }
            }, context: UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque()))

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
            CMTimeAdd(trimRange.start, CMTime(value: trimRange.duration.value * Int64(i) / Int64(numberOfPages), timescale: trimRange.duration.timescale))
        }

        // generate thumbnails for each page in background
        let generator = AVAssetImageGenerator(asset: item.asset) ※ {
            let scale = window?.backingScaleFactor ?? 1
            $0.maximumSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
            $0.requestedTimeToleranceBefore = imageGeneratorTolerance
            $0.requestedTimeToleranceAfter = imageGeneratorTolerance
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
            let p = CGFloat(CMTimeSubtract(time, trimRange.start).convertScale(trimRange.duration.timescale, method: CMTimeRoundingMethod.Default).value)
                / CGFloat(trimRange.duration.value)
            currentTimeBar.hidden = false
            currentTimeBar.frame = NSRect(x: p * bounds.width, y: 0, width: 1, height: bounds.height)
            currentTimeLabel.stringValue = time.stringInmmssSS
        } else {
            currentTimeBar.hidden = true
            currentTimeLabel.stringValue = "--:--.--"
        }
    }

    private func updateScope() {
        if let s = scopeRange {
            let startPercent = CGFloat(CMTimeSubtract(s.start, trimRange.start).convertScale(trimRange.duration.timescale, method: CMTimeRoundingMethod.Default).value)
                / CGFloat(trimRange.duration.value)
            let endPercent = CGFloat(CMTimeSubtract(s.end, trimRange.start).convertScale(trimRange.duration.timescale, method: CMTimeRoundingMethod.Default).value)
                / CGFloat(trimRange.duration.value)

            scopeMaskLeftView.hidden = false
            scopeMaskRightView.hidden = false

            scopeMaskLeftView.frame = NSRect(x: 0, y: 0, width: startPercent * bounds.width, height: bounds.height)
            scopeMaskRightView.frame = NSRect(x: endPercent * bounds.width, y: 0, width: bounds.width - endPercent * bounds.width, height: bounds.height)

            player.currentItem?.forwardPlaybackEndTime = s.end
        } else {
            scopeMaskLeftView.hidden = true
            scopeMaskRightView.hidden = true

            player.currentItem?.forwardPlaybackEndTime = trimRange.end
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
        let time = CMTimeAdd(CMTime(value: Int64(CGFloat(trimRange.duration.value) * p.x / bounds.width), timescale: trimRange.duration.timescale), trimRange.start)
        player.seekToTime(time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
}
