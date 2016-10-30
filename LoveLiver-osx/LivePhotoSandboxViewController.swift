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


private let livePhotoDuration: TimeInterval = 3
private let outputDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Pictures/LoveLiver")


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
    fileprivate let baseFilename: String
    fileprivate lazy var exportButton: NSButton = NSButton() ※ { b in
        b.bezelStyle = .RegularSquareBezelStyle
        b.title = "Create Live Photo"
        b.target = self
        b.action = #selector(self.export)
    }
    fileprivate var exportSession: AVAssetExportSession?

    fileprivate lazy var closeButton: NSButton = NSButton() ※ { b in
        b.bezelStyle = .RegularSquareBezelStyle
        b.title = "Close"
        b.target = self
        b.action = #selector(self.close)
    }
    var closeAction: ((Void) -> Void)?

    fileprivate func updateButtons() {
        exportButton.isEnabled = (exportSession == nil)
    }

    fileprivate let player: AVPlayer
    fileprivate let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .None
    }
    fileprivate let overview: MovieOverviewControl

    fileprivate let startFrameView = NSImageView()
    fileprivate let endFrameView = NSImageView()
    fileprivate let imageGenerator: AVAssetImageGenerator
    fileprivate func updateImages() {
        imageGenerator.cancelAllCGImageGeneration()
        imageGenerator.generateCGImagesAsynchronously(forTimes: [startTime, endTime].map {NSValue(time: $0)}) { (requestedTime, cgImage, actualTime, result, error) in
            guard let cgImage = cgImage, result == .succeeded else { return }

            DispatchQueue.main.async {
                if requestedTime == self.startTime {
                    self.startFrameView.image = NSImage(cgImage: cgImage, size: NSZeroSize)
                }
                if requestedTime == self.endTime {
                    self.endFrameView.image = NSImage(cgImage: cgImage, size: NSZeroSize)
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
    fileprivate let startLabel = label()
    fileprivate let beforePosterLabel = label()
    fileprivate let posterLabel = label()
    fileprivate let afterPosterLabel = label()
    fileprivate let endLabel = label()
    fileprivate func updateLabels() {
        startLabel.stringValue = startTime.stringInmmssSS
        beforePosterLabel.stringValue = " ~ \(CMTimeSubtract(posterTime, startTime).stringInsSS) ~ "
        posterLabel.stringValue = posterTime.stringInmmssSS
        afterPosterLabel.stringValue = " ~ \(CMTimeSubtract(endTime, posterTime).stringInsSS) ~ "
        endLabel.stringValue = endTime.stringInmmssSS
    }
    fileprivate func updateScope() {
        let duration = player.currentItem?.duration ?? kCMTimeZero

        if CMTimeMaximum(kCMTimeZero, startTime) == kCMTimeZero {
            // scope is clipped by zero. underflow scope start by subtracting from end
            overview.scopeRange = CMTimeRange(start: CMTimeSubtract(endTime, CMTime(seconds: livePhotoDuration, preferredTimescale: posterTime.timescale)), end: endTime)
        } else if CMTimeMinimum(duration, endTime) == duration {
            // scope is clipped by movie end. overflow scope end by adding to start
            overview.scopeRange = CMTimeRange(start: startTime, end: CMTimeAdd(startTime, CMTime(seconds: livePhotoDuration, preferredTimescale: posterTime.timescale)))
        } else {
            overview.scopeRange = CMTimeRange(start: startTime, end: endTime)
        }
    }

    init!(player: AVPlayer, baseFilename: String) {
        guard let asset = player.currentItem?.asset else { return nil }
        let item = AVPlayerItem(asset: asset)

        self.baseFilename = baseFilename
        posterTime = CMTimeConvertScale(player.currentTime(), max(600, player.currentTime().timescale), .default) // timescale = 1 (too inaccurate) when posterTime = 0
        let duration = item.duration
        let offset = CMTime(seconds: livePhotoDuration / 2, preferredTimescale: posterTime.timescale)
        startTime = CMTimeMaximum(kCMTimeZero, CMTimeSubtract(posterTime, offset))
        endTime = CMTimeMinimum(CMTimeAdd(posterTime, offset), duration)

        self.player = AVPlayer(playerItem: item)

        imageGenerator = AVAssetImageGenerator(asset: asset) ※ { g -> Void in
            g.requestedTimeToleranceBefore = kCMTimeZero
            g.requestedTimeToleranceAfter = kCMTimeZero
            g.maximumSize = CGSize(width: 128 * 2, height: 128 * 2)
        }

        overview = MovieOverviewControl(player: self.player, playerItem: item)
        overview.draggingMode = .scope
        overview.imageGeneratorTolerance = kCMTimeZero

        super.init(nibName: nil, bundle: nil)

        self.player.volume = player.volume
        self.player.actionAtItemEnd = .pause
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
            playerView.addConstraint(NSLayoutConstraint(item: playerView, attribute: .height, relatedBy: .equal,
                toItem: playerView, attribute: .width, multiplier: videoSize.height / videoSize.width, constant: 0))

            startFrameView.addConstraint(NSLayoutConstraint(item: startFrameView, attribute: .width, relatedBy: .equal, toItem: startFrameView, attribute: .height, multiplier: videoSize.width / videoSize.height, constant: 0))
        }

        updateLabels()
        updateImages()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        let trimStart = CMTimeSubtract(posterTime, CMTime(seconds: livePhotoDuration, preferredTimescale: posterTime.timescale))
        let trimEnd = CMTimeAdd(posterTime, CMTime(seconds: livePhotoDuration, preferredTimescale: posterTime.timescale))
        overview.trimRange = CMTimeRange(start: trimStart, end: trimEnd)
        overview.shouldUpdateScopeRange = {[weak self] scopeRange in
            guard let `self` = self,
                let scopeRange = scopeRange else { return false }
            return CMTimeRangeContainsTime(scopeRange, self.posterTime)
        }
        overview.onScopeChange = {[weak self] dragging in self?.onScopeChange(dragging)}
        updateScope()

        // hook playerView click
        let playerViewClickGesture = NSClickGestureRecognizer(target: self, action: #selector(playOrPause))
        playerView.addGestureRecognizer(playerViewClickGesture)
    }

    func onScopeChange(_ dragging: Bool) {
        guard let s = overview.scopeRange?.start,
            let e = overview.scopeRange?.end else { return }
        startTime = CMTimeMaximum(kCMTimeZero, s)
        endTime = CMTimeMinimum(player.currentItem?.duration ?? kCMTimeZero, e)

        if !dragging {
            updateImages()
        }
    }

    @objc fileprivate func export() {
        guard let asset = player.currentItem?.asset else { return }
        let imageGenerator = AVAssetImageGenerator(asset: asset) ※ {
            $0.requestedTimeToleranceBefore = kCMTimeZero
            $0.requestedTimeToleranceAfter = kCMTimeZero
        }
        guard let image = imageGenerator.copyImage(at: posterTime) else { return }
        guard let _ = try? FileManager.default.createDirectory(atPath: outputDir.path, withIntermediateDirectories: true, attributes: nil) else { return }

        let assetIdentifier = UUID().uuidString
        let basename = [
            baseFilename,
            posterTime.stringInmmmsssSS,
            assetIdentifier].joined(separator: "-")
        let tmpImagePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(basename).tiff").path
        let tmpMoviePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(basename).mov").path
        let imagePath = outputDir.appendingPathComponent("\(basename).JPG").path
        let moviePath = outputDir.appendingPathComponent("\(basename).MOV").path
        let paths = [tmpImagePath, tmpMoviePath, imagePath, moviePath]

        for path in paths {
            guard !FileManager.default.fileExists(atPath: path) else { return }
        }

        guard image.TIFFRepresentation?.writeToFile(tmpImagePath, atomically: true) == true else { return }
        // create AVAssetExportSession each time because it cannot be reused after export completion
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return }
        session.outputFileType = "com.apple.quicktime-movie"
        session.outputURL = URL(fileURLWithPath: tmpMoviePath)
        session.timeRange = CMTimeRange(start: startTime, end: endTime)
        session.exportAsynchronously {
            DispatchQueue.main.async {
                switch session.status {
                case .completed:
                    JPEG(path: tmpImagePath).write(imagePath, assetIdentifier: assetIdentifier)
                    NSLog("%@", "LivePhoto JPEG created: \(imagePath)")

                    QuickTimeMov(path: tmpMoviePath).write(moviePath, assetIdentifier: assetIdentifier)
                    NSLog("%@", "LivePhoto MOV created: \(moviePath)")

                    self.showInFinderAndOpenInPhotos([imagePath, moviePath].map{URL(fileURLWithPath: $0)})
                case .cancelled, .exporting, .failed, .unknown, .waiting:
                    NSLog("%@", "exportAsynchronouslyWithCompletionHandler = \(session.status)")
                }

                for path in [tmpImagePath, tmpMoviePath] {
                    let _ = try? FileManager.default.removeItem(atPath: path)
                }
                self.exportSession = nil
                self.updateButtons()
            }
        }
        exportSession = session
        updateButtons()
    }

    fileprivate func showInFinderAndOpenInPhotos(_ fileURLs: [URL]) {
        NSWorkspace.shared().activateFileViewerSelecting(fileURLs)

        // wait until Finder is active or timed out,
        // to avoid openURLs overtaking Finder activation
        DispatchQueue.global(priority: 0).async {
            let start = Date()
            while NSWorkspace.shared().frontmostApplication?.bundleIdentifier != "com.apple.finder" && Date().timeIntervalSince(start) < 5 {
                Thread.sleep(forTimeInterval: 0.1)
            }
            NSWorkspace.shared().open(fileURLs, withAppBundleIdentifier: "com.apple.Photos", options: [], additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        }
    }

    @objc fileprivate func close() {
        closeAction?()
    }

    @objc fileprivate func play() {
        player.seek(to: startTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player.play()
    }

    @objc fileprivate func pause() {
        player.pause()
    }

    @objc fileprivate func playOrPause() {
        if player.rate == 0 {
            play()
        } else {
            pause()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch (object, keyPath) {
        case (is AVPlayer, _):
            let stopped = (player.rate == 0)
            if stopped {
                player.seek(to: posterTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
            break
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
