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


class MovieDocumentViewController: NSViewController {
    private let movieURL: NSURL
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    private let imageGenerator: AVAssetImageGenerator
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

    init!(movieURL: NSURL, playerItem: AVPlayerItem, player: AVPlayer) {
        self.movieURL = movieURL
        self.playerItem = playerItem
        self.player = player
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
        autolayout("V:|-p-[player]-p-[posterButton]-p-|")
        autolayout("V:|-p-[posterView][positionsLabel(==p)][createLivePhoto]-p-|")

        updateViews()
    }

    func movieDidLoad(videoSize: CGSize) {
        self.playerView.addConstraint(NSLayoutConstraint(
            item: self.playerView, attribute: .Width, relatedBy: .Equal,
            toItem: self.playerView, attribute: .Height, multiplier: videoSize.width / videoSize.height, constant: 0))
    }

    private func updateViews() {
        createLivePhotoButton.enabled = (posterFrameView.image != nil)
        positionsLabel.stringValue = positionsLabelText
    }

    private var positionsLabelText: String {
        guard let time = posterFrameTime else { return "" }
        return "Poster Frame: \(time.stringInmmssSS)"
    }

    @objc private func capturePosterFrame(sender: AnyObject?) {
        posterFrameView.image = imageGenerator.copyImage(at: player.currentTime())
        posterFrameTime = player.currentTime()
        updateViews()

        let livephotoSandboxVC = LivePhotoSandboxViewController(player: player, baseFilename: movieURL.lastPathComponent ?? "unknown")
        let popover = NSPopover()
        livephotoSandboxVC.closeAction = {
            popover.performClose(nil)
        }
        popover.behavior = .Semitransient
        popover.contentViewController = livephotoSandboxVC
        popover.showRelativeToRect(posterFrameButton.bounds, ofView: posterFrameButton, preferredEdge: NSRectEdge.MinY)
    }
}
