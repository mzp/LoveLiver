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


class MovieDocumentViewController: NSViewController {
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

    init!(movieURL: NSURL) {
        super.init(nibName: nil, bundle: nil)
        playerView.player = AVPlayer(URL: movieURL)
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
            ])
        autolayout("H:|-p-[player]-p-[posterView(==player)]-p-|")
        autolayout("H:|-p-[posterButton(==player)]")
        autolayout("V:|-p-[player]-p-[posterButton]")
        autolayout("V:|-p-[posterView]-p-[posterButton]")
        autolayout("V:[posterButton]-p-|")

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
        guard let player = playerView.player else { return }
        guard let asset = player.currentItem?.asset else { return }

        let generator = AVAssetImageGenerator(asset: asset)
        guard let cgImage = try? generator.copyCGImageAtTime(player.currentTime(), actualTime: nil) else { return }
        let image = NSImage(CGImage: cgImage, size: CGSize(width: CGImageGetWidth(cgImage), height: CGImageGetHeight(cgImage)))
        posterFrameView.image = image
    }
}
