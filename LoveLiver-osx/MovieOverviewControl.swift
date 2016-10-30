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
    fileprivate(set) lazy var currentTimeBar: NSView = NSView(frame: NSZeroRect) ※ { v in
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.red.cgColor
        self.addSubview(v)
    }
    fileprivate lazy var currentTimeLabel: NSTextField = NSTextField(frame: NSZeroRect) ※ { tf in
        tf.isBezeled = false
        tf.isEditable = false
        tf.drawsBackground = true
        tf.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: NSFontWeightRegular)
        tf.textColor = NSColor.white
        tf.backgroundColor = NSColor.black
    }

    var imageGenerator: AVAssetImageGenerator?
    var numberOfPages: UInt = 0 {
        didSet { setNeedsDisplay(bounds) }
    }
    var thumbnails = [NSImage]()
    var imageGeneratorTolerance = CMTime(seconds: 300, preferredTimescale: 600)

    // overview control supports timmed playback and scope edit
    var trimRange: CMTimeRange { didSet { reload() } } // show overview only within trimRange
    var scopeRange: CMTimeRange? { // if non-nil, shows scope control
        didSet {
            if let old = oldValue, let new = scopeRange, CMTimeRangeEqual(old, new) {
                return
            }
            updateScope()
            onScopeChange?(mouseDownLocation != nil)
        }
    }
    var shouldUpdateScopeRange: ((_ newValue: CMTimeRange?) -> Bool)?
    var onScopeChange: ((_ dragging: Bool) -> Void)?
    fileprivate lazy var scopeMaskLeftView: NSView = NSView(frame: NSZeroRect) ※ { v in
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(white: 0, alpha: 0.75).cgColor
        v.isHidden = true
    }
    fileprivate lazy var scopeMaskRightView: NSView = NSView(frame: NSZeroRect) ※ { v in
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(white: 0, alpha: 0.75).cgColor
        v.isHidden = true
    }

    enum DraggingMode {
        case seek, scope
    }
    var draggingMode = DraggingMode.seek

    init(player: AVPlayer, playerItem: AVPlayerItem) {
        self.player = player
        self.trimRange = CMTimeRange(start: kCMTimeZero, duration: playerItem.duration)
        
        super.init(frame: NSZeroRect)

        let autolayout = northLayoutFormat([:], [
            "currentTime": currentTimeLabel,
            ])
        autolayout("H:|[currentTime]")
        autolayout("V:[currentTime]|")

        setContentCompressionResistancePriority(NSLayoutPriorityDefaultHigh, for: .vertical)
        setContentHuggingPriority(NSLayoutPriorityDefaultHigh, for: .vertical)

        // subviews ordering
        addSubview(scopeMaskLeftView)
        addSubview(scopeMaskRightView)
        sortSubviews({ (v1, v2, context) -> ComparisonResult in
            let s = Unmanaged<MovieOverviewControl>.fromOpaque(context!).takeUnretainedValue()
            switch (v1, v2) {
            case (s.currentTimeLabel, _): return .orderedDescending
            default: return .orderedSame
            }
            }, context: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

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
        generator.generateCGImagesAsynchronously(forTimes: times.map {NSValue(time: $0)}) { (requestedTime, cgImage, actualTime, result, error) -> Void in
            guard let cgImage = cgImage, result == .succeeded else { return }

            let thumb = NSImage(cgImage: cgImage, size: NSZeroSize)

            DispatchQueue.main.async {
                guard self.imageGenerator === generator else { return } // avoid appending result from outdated requests
                self.thumbnails.append(thumb)
                self.setNeedsDisplay(self.bounds)
            }
        }
    }

    func observePlayer() {
        if let playerTimeObserver = playerTimeObserver {
            player.removeTimeObserver(playerTimeObserver)
        }

        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: DispatchQueue.main) { [weak self] time in
            self?.currentTime = time
        } as AnyObject?
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()

        reload()
    }

    override var frame: NSRect {
        didSet { updateCurrentTime() }
    }

    fileprivate func updateCurrentTime() {
        if let time = currentTime {
            let p = CGFloat(CMTimeSubtract(time, trimRange.start).convertScale(trimRange.duration.timescale, method: CMTimeRoundingMethod.default).value)
                / CGFloat(trimRange.duration.value)
            currentTimeBar.isHidden = false
            currentTimeBar.frame = NSRect(x: p * bounds.width, y: 0, width: 1, height: bounds.height)
            currentTimeLabel.stringValue = time.stringInmmssSS
        } else {
            currentTimeBar.isHidden = true
            currentTimeLabel.stringValue = "--:--.--"
        }
    }

    fileprivate func updateScope() {
        if let s = scopeRange {
            let startPercent = CGFloat(CMTimeSubtract(s.start, trimRange.start).convertScale(trimRange.duration.timescale, method: CMTimeRoundingMethod.default).value)
                / CGFloat(trimRange.duration.value)
            let endPercent = CGFloat(CMTimeSubtract(s.end, trimRange.start).convertScale(trimRange.duration.timescale, method: CMTimeRoundingMethod.default).value)
                / CGFloat(trimRange.duration.value)

            scopeMaskLeftView.isHidden = false
            scopeMaskRightView.isHidden = false

            scopeMaskLeftView.frame = NSRect(x: 0, y: 0, width: startPercent * bounds.width, height: bounds.height)
            scopeMaskRightView.frame = NSRect(x: endPercent * bounds.width, y: 0, width: bounds.width - endPercent * bounds.width, height: bounds.height)

            updateForwardPlaybackEndTime()
        } else {
            scopeMaskLeftView.isHidden = true
            scopeMaskRightView.isHidden = true

            player.currentItem?.forwardPlaybackEndTime = trimRange.end
        }
    }

    fileprivate func updateForwardPlaybackEndTime() {
        // scope playback to end of scopeRange
        // this is relatively heavy operation. ignore on dragging

        if let s = scopeRange, mouseDownLocation == nil {
            player.currentItem?.forwardPlaybackEndTime = s.end
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        NSRectFillUsingOperation(dirtyRect, .copy)

        var x: CGFloat = 0
        for t in thumbnails {
            let pageRect = NSRect(x: x, y: 0, width: bounds.height / t.size.height * t.size.width, height: bounds.height)
            t.draw(in: pageRect)
            x += pageRect.width
        }
    }

    fileprivate var mouseDownLocation: NSPoint?
    fileprivate var scopeRangeOnMouseDown: CMTimeRange?

    override func mouseDown(with theEvent: NSEvent) {
        mouseDownLocation = convert(theEvent.locationInWindow, from: nil)
        scopeRangeOnMouseDown = scopeRange

        switch draggingMode {
        case .seek: seekToMousePosition(theEvent)
        case .scope: break
        }
    }

    override func mouseDragged(with theEvent: NSEvent) {
        switch draggingMode {
        case .seek: seekToMousePosition(theEvent)
        case .scope: scopeToMousePosition(theEvent)
        }
    }

    override func mouseUp(with theEvent: NSEvent) {
        mouseDownLocation = nil
        scopeRangeOnMouseDown = nil

        switch draggingMode {
        case .seek: break
        case .scope:
            onScopeChange?(false)
            updateForwardPlaybackEndTime()
        }
    }

    fileprivate func seekToMousePosition(_ theEvent: NSEvent) {
        let p = convert(theEvent.locationInWindow, from: nil)
        let time = CMTimeAdd(CMTime(value: Int64(CGFloat(trimRange.duration.value) * p.x / bounds.width), timescale: trimRange.duration.timescale), trimRange.start)
        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    fileprivate func scopeToMousePosition(_ theEvent: NSEvent) {
        guard let mouseDownLocation = mouseDownLocation,
            let s = scopeRangeOnMouseDown,
            let minFrameDuration = player.currentItem?.minFrameDuration else { return }
        let p = convert(theEvent.locationInWindow, from: nil)

        let distance = Int32(p.x - mouseDownLocation.x)
        let start = CMTimeAdd(s.start, CMTimeMultiply(minFrameDuration, distance))
        let end = CMTimeAdd(s.end, CMTimeMultiply(minFrameDuration, distance))
        let newScopeRange = CMTimeRange(start: start, end: end)

        if shouldUpdateScopeRange?(newScopeRange) == true {
            scopeRange = newScopeRange
        }
    }
}
