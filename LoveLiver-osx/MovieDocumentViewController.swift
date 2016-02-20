//
//  MovieDocumentViewController.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/02/09.
//  Copyright © 2016 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import NorthLayout
import Ikemen


private let outputDir = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Pictures/LoveLiver")


class MovieDocumentViewController: NSViewController {
    private let movieURL: NSURL
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    private let imageGenerator: AVAssetImageGenerator
    private var exportSession: AVAssetExportSession?
    private var posterFrameTime: CMTime?

    private let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .Floating
        v.showsFrameSteppingButtons = true
    }
    private let posterFrameView = NSImageView() ※ { v in
        v.imageScaling = .ScaleProportionallyUpOrDown
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.blackColor().CGColor
        v.setContentCompressionResistancePriority(NSLayoutPriorityFittingSizeCompression, forOrientation: .Horizontal)
        v.setContentCompressionResistancePriority(NSLayoutPriorityFittingSizeCompression, forOrientation: .Vertical)
    }
    private lazy var posterFrameButton: NSButton = NSButton() ※ { b in
        b.title = "Poster Frame ->>"
        b.setButtonType(.MomentaryLightButton)
        b.bezelStyle = .RoundedBezelStyle
        b.target = self
        b.action = "capturePosterFrame:"
    }

    private lazy var positionsLabel: NSTextField = NSTextField() ※ { tf in
        tf.bezeled = false
        tf.editable = false
        tf.drawsBackground = false
        tf.textColor = NSColor.grayColor()
    }

    private lazy var createLivePhotoButton: NSButton = NSButton() ※ { b in
        b.title = "Create Live Photo"
        b.setButtonType(.MomentaryLightButton)
        b.bezelStyle = .RoundedBezelStyle
        b.target = self
        b.action = "createLivePhoto:"
    }

    init!(movieURL: NSURL) {
        self.movieURL = movieURL
        playerItem = AVPlayerItem(URL: movieURL)
        player = AVPlayer(playerItem: playerItem)
        playerView.player = player
        imageGenerator = AVAssetImageGenerator(asset: playerItem.asset) ※ {
            $0.requestedTimeToleranceBefore = kCMTimeZero
            $0.requestedTimeToleranceAfter = kCMTimeZero
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))

        let autolayout = view.northLayoutFormat(["p": 20], [
            "player": playerView,
            "posterButton": posterFrameButton,
            "posterView": posterFrameView,
            "createLivePhoto": createLivePhotoButton,
            "positionsLabel": positionsLabel,
            ])
        autolayout("H:|-p-[player]-p-[posterView(==player)]-p-|")
        autolayout("H:|-p-[posterButton(==player)]-p-[createLivePhoto(<=player)]-p-|")
        autolayout("H:[positionsLabel(==createLivePhoto)]-p-|")
        autolayout("V:|-p-[player]-p-[posterButton]")
        autolayout("V:|-p-[posterView]-p-[posterButton]")
        autolayout("V:[posterButton]-p-|")
        autolayout("V:[posterView][positionsLabel][createLivePhoto]-p-|")

        setupAspectRatioConstraints()
        updateViews()
    }

    private func setupAspectRatioConstraints() {
        // wait until movie is loaded
        guard playerView.videoBounds.width > 0 && playerView.videoBounds.height > 0 else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.setupAspectRatioConstraints()
            }
            return
        }

        self.playerView.addConstraint(NSLayoutConstraint(
            item: self.playerView, attribute: .Width, relatedBy: .Equal,
            toItem: self.playerView, attribute: .Height, multiplier: self.playerView.videoBounds.width / self.playerView.videoBounds.height, constant: 0))
    }

    private func updateViews() {
        createLivePhotoButton.enabled = (posterFrameView.image != nil && exportSession == nil)
        positionsLabel.stringValue = positionsLabelText
    }

    private var positionsLabelText: String {
        guard let time = posterFrameTime else { return "" }
        return "Poster Frame: \(time.stringInmmssSS)"
    }

    @objc private func capturePosterFrame(sender: AnyObject?) {
        guard let cgImage = try? imageGenerator.copyCGImageAtTime(player.currentTime(), actualTime: nil) else { return }
        let image = NSImage(CGImage: cgImage, size: CGSize(width: CGImageGetWidth(cgImage), height: CGImageGetHeight(cgImage)))
        posterFrameView.image = image
        posterFrameTime = player.currentTime()
        updateViews()
    }

    @objc private func createLivePhoto(sender: AnyObject?) {
        guard let image = posterFrameView.image else { return }

        guard let _ = try? NSFileManager.defaultManager().createDirectoryAtPath(outputDir.path!, withIntermediateDirectories: true, attributes: nil) else { return }

        let assetIdentifier = NSUUID().UUIDString
        let basename = [
            movieURL.lastPathComponent ?? "",
            player.currentTime().stringInmmmsssSS,
            assetIdentifier].joinWithSeparator("-")
        let tmpImagePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(basename).tiff").path!
        let tmpMoviePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(basename).mov").path!
        let imagePath = outputDir.URLByAppendingPathComponent("\(basename).JPG").path!
        let moviePath = outputDir.URLByAppendingPathComponent("\(basename).MOV").path!
        let paths = [tmpImagePath, tmpMoviePath, imagePath, moviePath]

        for path in paths {
            guard !NSFileManager.defaultManager().fileExistsAtPath(path) else { return }
        }

        guard image.TIFFRepresentation?.writeToFile(tmpImagePath, atomically: true) == true else { return }
        // create AVAssetExportSession each time because it cannot be reused after export completion
        guard let session = AVAssetExportSession(asset: playerItem.asset, presetName: AVAssetExportPresetPassthrough) else { return }
        session.outputFileType = "com.apple.quicktime-movie"
        session.outputURL = NSURL(fileURLWithPath: tmpMoviePath)
        session.timeRange = CMTimeRange(start: player.currentTime(), duration: CMTime(value: 3*600, timescale: 600))
        session.exportAsynchronouslyWithCompletionHandler {
            dispatch_async(dispatch_get_main_queue()) {
                switch session.status {
                case .Completed:
                    JPEG(path: tmpImagePath).write(imagePath, assetIdentifier: assetIdentifier)
                    NSLog("%@", "LivePhoto JPEG created: \(imagePath)")

                    QuickTimeMov(path: tmpMoviePath).write(moviePath, assetIdentifier: assetIdentifier)
                    NSLog("%@", "LivePhoto MOV created: \(moviePath)")

                    self.showInFinderAndOpenInPhotos([imagePath, moviePath].map{NSURL(fileURLWithPath: $0)})
                case .Cancelled, .Exporting, .Failed, .Unknown, .Waiting:
                    NSLog("%@", "exportAsynchronouslyWithCompletionHandler = \(session.status)")
                }

                for path in [tmpImagePath, tmpMoviePath] {
                    let _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
                }
                self.exportSession = nil
                self.updateViews()
            }
        }
        exportSession = session
        updateViews()
    }

    private func showInFinderAndOpenInPhotos(fileURLs: [NSURL]) {
        NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs(fileURLs)

        // wait until Finder is active or timed out,
        // to avoid openURLs overtaking Finder activation
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let start = NSDate()
            while NSWorkspace.sharedWorkspace().frontmostApplication?.bundleIdentifier != "com.apple.finder" && NSDate().timeIntervalSinceDate(start) < 5 {
                NSThread.sleepForTimeInterval(0.1)
            }
            NSWorkspace.sharedWorkspace().openURLs(fileURLs, withAppBundleIdentifier: "com.apple.Photos", options: [], additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        }
    }
}


extension CMTime {
    var msS: (Int, Int, Int) {
        let duration = CMTimeGetSeconds(self)
        let minutes = Int(floor(duration / 60))
        let seconds = Int(floor(duration - Double(minutes) * 60))
        let milliseconds = Int((duration - floor(duration)) * 100)
        return (minutes, seconds, milliseconds)
    }

    var stringInmmssSS: String {
        let (minutes, seconds, milliseconds) = msS
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }

    var stringInmmmsssSS: String {
        let (minutes, seconds, milliseconds) = msS
        return String(format: "%02dm%02ds%02d", minutes, seconds, milliseconds)
    }
}

