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
    fileprivate let movieURL: URL
    fileprivate let player: AVPlayer
    fileprivate let playerItem: AVPlayerItem
    var createLivePhotoAction: ((Void) -> Void)?

    fileprivate let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .floating
        v.showsFrameSteppingButtons = true
    }
    fileprivate lazy var posterFrameButton: NSButton = NSButton() ※ { b in
        b.title = "Live Photo With This Frame"
        b.setButtonType(.momentaryLight)
        b.bezelStyle = .rounded
        b.target = self
        b.action = #selector(self.createLivePhotoSandbox)
    }

    init!(movieURL: URL, playerItem: AVPlayerItem, player: AVPlayer) {
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

    func movieDidLoad(_ videoSize: CGSize) {
        self.playerView.addConstraint(NSLayoutConstraint(
            item: self.playerView, attribute: .width, relatedBy: .equal,
            toItem: self.playerView, attribute: .height, multiplier: videoSize.width / videoSize.height, constant: 0))
    }

    @objc fileprivate func createLivePhotoSandbox() {
        player.pause()
        createLivePhotoAction?()
    }
}
