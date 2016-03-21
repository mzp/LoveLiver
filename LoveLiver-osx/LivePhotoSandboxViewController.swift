//
//  LivePhotoSandboxViewController.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/03/21.
//  Copyright © 2016年 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import NorthLayout
import Ikemen


private let livePhotoDuration: NSTimeInterval = 3


private func label() -> NSTextField {
    return NSTextField() ※ { tf in
        tf.bezeled = false
        tf.editable = false
        tf.drawsBackground = false
        tf.textColor = NSColor.grayColor()
        tf.font = NSFont.monospacedDigitSystemFontOfSize(12, weight: NSFontWeightRegular)
    }
}


class LivePhotoSandboxViewController: NSViewController {
    private lazy var exportButton: NSButton = NSButton() ※ { b in
        b.bezelStyle = .RegularSquareBezelStyle
        b.title = "Create Live Photo"
        b.target = self
        b.action = "export"
    }
    private lazy var closeButton: NSButton = NSButton() ※ { b in
        b.bezelStyle = .RegularSquareBezelStyle
        b.title = "Close"
        b.target = self
        b.action = "close"
    }
    var closeAction: (Void -> Void)?

    private let player: AVPlayer
    private let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .None
    }
    private let overview: MovieOverviewControl

    private let startFrameView = NSImageView()
    private let endFrameView = NSImageView()
    private let imageGenerator: AVAssetImageGenerator
    private func updateImages() {
        imageGenerator.cancelAllCGImageGeneration()
        imageGenerator.generateCGImagesAsynchronouslyForTimes([startTime, endTime].map {NSValue(CMTime: $0)}) { (requestedTime, cgImage, actualTime, result, error) in
            guard let cgImage = cgImage where result == .Succeeded else { return }

            dispatch_async(dispatch_get_main_queue()) {
                if requestedTime == self.startTime {
                    self.startFrameView.image = NSImage(CGImage: cgImage, size: NSZeroSize)
                }
                if requestedTime == self.endTime {
                    self.endFrameView.image = NSImage(CGImage: cgImage, size: NSZeroSize)
                }
            }
        }
    }

    var startTime: CMTime {
        didSet {
            updateLabels()
            updateScope()
        }
    }
    var posterTime: CMTime { didSet { updateLabels() } }
    var endTime: CMTime {
        didSet {
            updateLabels()
            updateScope()
        }
    }
    private let startLabel = label()
    private let beforePosterLabel = label()
    private let posterLabel = label()
    private let afterPosterLabel = label()
    private let endLabel = label()
    private func updateLabels() {
        startLabel.stringValue = startTime.stringInmmssSS
        beforePosterLabel.stringValue = " ~ \(CMTimeSubtract(posterTime, startTime).stringInsSS) ~ "
        posterLabel.stringValue = posterTime.stringInmmssSS
        afterPosterLabel.stringValue = " ~ \(CMTimeSubtract(endTime, posterTime).stringInsSS) ~ "
        endLabel.stringValue = endTime.stringInmmssSS
    }
    private func updateScope() {
        overview.scopeRange = CMTimeRange(start: startTime, end: endTime)
    }

    init!(player: AVPlayer) {
        // use guard let and return nil with Swift 2.2
        let asset = player.currentItem?.asset
        let item = asset.map {AVPlayerItem(asset: $0)}

        posterTime = player.currentTime()
        let duration = item?.duration ?? kCMTimeZero
        let offset = CMTime(seconds: livePhotoDuration / 2, preferredTimescale: posterTime.timescale)
        startTime = CMTimeMaximum(kCMTimeZero, CMTimeSubtract(posterTime, offset))
        endTime = CMTimeMinimum(CMTimeAdd(posterTime, offset), duration)

        self.player = item.map {AVPlayer(playerItem: $0)} ?? player

        imageGenerator = AVAssetImageGenerator(asset: asset ?? AVAsset()) ※ { g -> Void in
            g.requestedTimeToleranceBefore = kCMTimeZero
            g.requestedTimeToleranceAfter = kCMTimeZero
            g.maximumSize = CGSize(width: 128 * 2, height: 128 * 2)
        }

        overview = MovieOverviewControl(player: self.player, playerItem: item ?? AVPlayerItem(asset: AVAsset()))
        overview.draggingMode = .Scope
        overview.imageGeneratorTolerance = kCMTimeZero

        super.init(nibName: nil, bundle: nil)
        guard let _ = item else { return nil }

        self.player.volume = player.volume
        self.player.actionAtItemEnd = .Pause
        self.playerView.player = self.player

        self.player.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        play()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        player.removeObserver(self, forKeyPath: "rate")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))

        let autolayout = view.northLayoutFormat(["p": 8], [
            "export": exportButton,
            "close": closeButton,
            "player": playerView,
            "overview": overview,
            "startFrame": startFrameView,
            "startLabel": startLabel,
            "beforePosterLabel": beforePosterLabel,
            "posterLabel": posterLabel,
            "afterPosterLabel": afterPosterLabel,
            "endFrame": endFrameView,
            "endLabel": endLabel,
            "spacerLL": NSView(),
            "spacerLR": NSView(),
            "spacerRL": NSView(),
            "spacerRR": NSView(),
            ])
        autolayout("H:|-p-[close]-(>=p)-[export]-p-|")
        autolayout("H:|-p-[player(>=300)]-p-|")
        autolayout("H:|-p-[startFrame]-(>=p)-[endFrame(==startFrame)]-p-|")
        autolayout("H:|-p-[startLabel][spacerLL][beforePosterLabel][spacerLR(==spacerLL)][posterLabel][spacerRL(==spacerLL)][afterPosterLabel][spacerRR(==spacerLL)][endLabel]-p-|")
        autolayout("H:|-p-[overview]-p-|")
        autolayout("V:|-p-[export]-p-[player(>=300)]")
        autolayout("V:|-p-[close]-p-[player]")
        autolayout("V:[player][overview(==64)]")
        autolayout("V:[overview]-p-[startFrame(==128)][startLabel]-p-|")
        autolayout("V:[startFrame][beforePosterLabel]")
        autolayout("V:[startFrame][posterLabel]")
        autolayout("V:[startFrame][afterPosterLabel]")
        autolayout("V:[overview]-p-[endFrame(==startFrame)][endLabel]-p-|")

        if let videoSize = player.currentItem?.naturalSize {
            playerView.addConstraint(NSLayoutConstraint(item: playerView, attribute: .Height, relatedBy: .Equal,
                toItem: playerView, attribute: .Width, multiplier: videoSize.height / videoSize.width, constant: 0))

            startFrameView.addConstraint(NSLayoutConstraint(item: startFrameView, attribute: .Width, relatedBy: .Equal, toItem: startFrameView, attribute: .Height, multiplier: videoSize.width / videoSize.height, constant: 0))
        }

        updateLabels()
        updateImages()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        let trimStart = CMTimeSubtract(posterTime, CMTime(seconds: livePhotoDuration, preferredTimescale: posterTime.timescale))
        overview.trimRange = CMTimeRange(start: trimStart, duration: CMTime(seconds: livePhotoDuration * 2, preferredTimescale: posterTime.timescale))
        overview.onScopeChange = {[weak self] dragging in self?.onScopeChange(dragging)}
        updateScope()

        // hook playerView click
        let playerViewClickGesture = NSClickGestureRecognizer(target: self, action: "playOrPause")
        playerView.addGestureRecognizer(playerViewClickGesture)
    }

    func onScopeChange(dragging: Bool) {
        guard let s = overview.scopeRange?.start,
            let e = overview.scopeRange?.end else { return }
        startTime = s
        endTime = e

        if !dragging {
            updateImages()
        }
    }

    @objc private func export() {
        NSLog("%@", "TODO: export live photo")
    }

    @objc private func close() {
        closeAction?()
    }

    @objc private func play() {
        player.seekToTime(startTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player.play()
    }

    @objc private func pause() {
        player.pause()
    }

    @objc private func playOrPause() {
        if player.rate == 0 {
            play()
        } else {
            pause()
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch (object, keyPath) {
        case (is AVPlayer, _):
            let stopped = (player.rate == 0)
            if stopped {
                player.seekToTime(posterTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
            break
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}