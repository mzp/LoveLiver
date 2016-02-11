//
//  MovieDocumentViewController.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/02/09.
//  Copyright © 2016年 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import NorthLayout
import Ikemen


private let outputDir = NSURL(fileURLWithPath: NSHomeDirectory()).URLByAppendingPathComponent("Pictures/LoveLiver")


class MovieDocumentViewController: NSViewController {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    private let imageGenerator: AVAssetImageGenerator

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
    private lazy var createLivePhotoButton: NSButton = NSButton() ※ { b in
        b.title = "Create Live Photo"
        b.setButtonType(.MomentaryLightButton)
        b.bezelStyle = .RoundedBezelStyle
        b.target = self
        b.action = "createLivePhoto:"
    }

    init!(movieURL: NSURL) {
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
            ])
        autolayout("H:|-p-[player]-p-[posterView(==player)]-p-|")
        autolayout("H:|-p-[posterButton(==player)]-p-[createLivePhoto(<=player)]-p-|")
        autolayout("V:|-p-[player]-p-[posterButton]")
        autolayout("V:|-p-[posterView]-p-[posterButton]")
        autolayout("V:[posterButton]-p-|")
        autolayout("V:[createLivePhoto]-p-|")

        setupAspectRatioConstraints()
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

    @objc private func capturePosterFrame(sender: AnyObject?) {
        guard let cgImage = try? imageGenerator.copyCGImageAtTime(player.currentTime(), actualTime: nil) else { return }
        let image = NSImage(CGImage: cgImage, size: CGSize(width: CGImageGetWidth(cgImage), height: CGImageGetHeight(cgImage)))
        posterFrameView.image = image
    }

    @objc private func createLivePhoto(sender: AnyObject?) {
        guard let image = posterFrameView.image else { return }

        guard let _ = try? NSFileManager.defaultManager().createDirectoryAtPath(outputDir.path!, withIntermediateDirectories: true, attributes: nil) else { return }

        let assetIdentifier = NSUUID().UUIDString
        let tmpImagePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(assetIdentifier).tiff").path!
        let tmpMoviePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(assetIdentifier).mov").path!
        let imagePath = outputDir.URLByAppendingPathComponent("\(assetIdentifier).JPG").path!
        let moviePath = outputDir.URLByAppendingPathComponent("\(assetIdentifier).MOV").path!
        let paths = [tmpImagePath, tmpMoviePath, imagePath, moviePath]

        for path in paths {
            guard !NSFileManager.defaultManager().fileExistsAtPath(path) else { return }
        }

        guard image.TIFFRepresentation?.writeToFile(tmpImagePath, atomically: true) == true else { return }
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
            }
        }
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
