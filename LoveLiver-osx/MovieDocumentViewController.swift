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

    private let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .Floating
        v.showsFrameSteppingButtons = true
    }
    private lazy var posterFrameButton: NSButton = NSButton() ※ { b in
        b.title = "Live Photo With This Frame"
        b.setButtonType(.MomentaryLightButton)
        b.bezelStyle = .RoundedBezelStyle
        b.target = self
        b.action = "createLivePhotoSandbox"
    }

    init!(movieURL: NSURL, playerItem: AVPlayerItem, player: AVPlayer) {
        self.movieURL = movieURL
        self.playerItem = playerItem
        self.player = player
        playerView.player = player
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))

        let autolayout = view.northLayoutFormat(["p": 16], [
            "player": playerView,
            "posterButton": posterFrameButton,
            ])
        autolayout("H:|[player]|")
        autolayout("H:|-p-[posterButton]-p-|")
        autolayout("V:|[player]-p-[posterButton]-p-|")
    }

    func movieDidLoad(videoSize: CGSize) {
        self.playerView.addConstraint(NSLayoutConstraint(
            item: self.playerView, attribute: .Width, relatedBy: .Equal,
            toItem: self.playerView, attribute: .Height, multiplier: videoSize.width / videoSize.height, constant: 0))
    }

    @objc private func createLivePhotoSandbox() {
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
