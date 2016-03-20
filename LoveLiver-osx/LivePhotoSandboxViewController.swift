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


class LivePhotoSandboxViewController: NSViewController {
    private let player: AVPlayer
    private let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .None
    }

    private let startFrameView = NSImageView()
    private let endFrameView = NSImageView()

    private lazy var playButton: NSButton = NSButton() ※ { b in
        b.setButtonType(.MomentaryLightButton)
        b.bezelStyle = .CircularBezelStyle
        b.target = self
    }
    private func updatePlayButton() {
        let playing = (player.rate != 0)
        playButton.title = playing ? "■" : "▶"
        playButton.action = playing ? "pause" : "play"

        if !playing {
            player.seekToTime(posterTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }

    var startTime: CMTime { didSet { updateLabels() } }
    var posterTime: CMTime { didSet { updateLabels() } }
    var endTime: CMTime { didSet { updateLabels() } }
    private lazy var startLabel: NSTextField = NSTextField() ※ self.label
    private lazy var posterLabel: NSTextField = NSTextField() ※ self.label
    private lazy var endLabel: NSTextField = NSTextField() ※ self.label
    private func label(tf: NSTextField) {
        tf.bezeled = false
        tf.editable = false
        tf.drawsBackground = false
        tf.textColor = NSColor.grayColor()
        tf.font = NSFont.monospacedDigitSystemFontOfSize(12, weight: NSFontWeightRegular)
    }
    private func updateLabels() {
        startLabel.stringValue = startTime.stringInmmssSS
        posterLabel.stringValue = posterTime.stringInmmssSS
        endLabel.stringValue = endTime.stringInmmssSS
    }

    init!(player: AVPlayer) {
        let asset = player.currentItem?.asset
        let item = asset.map {AVPlayerItem(asset: $0)}

        posterTime = player.currentTime()
        let duration = item?.duration ?? kCMTimeZero
        let livePhotoDuration: NSTimeInterval = 3
        let offset = CMTime(seconds: livePhotoDuration / 2, preferredTimescale: posterTime.timescale)
        startTime = CMTimeMaximum(kCMTimeZero, CMTimeSubtract(posterTime, offset))
        endTime = CMTimeMinimum(CMTimeAdd(posterTime, offset), duration)

        self.player = item.map {AVPlayer(playerItem: $0)} ?? player
        item?.forwardPlaybackEndTime = endTime

        super.init(nibName: nil, bundle: nil)
        guard let _ = item else { return nil }

        self.player.volume = player.volume
        self.player.actionAtItemEnd = .Pause
        self.playerView.player = self.player

        self.player.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        updatePlayButton()
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
            "player": playerView,
            "play": playButton,
            "startFrame": startFrameView,
            "startLabel": startLabel,
            "posterLabel": posterLabel,
            "endFrame": endFrameView,
            "endLabel": endLabel,
            "spacerL": NSView(),
            "spacerR": NSView(),
            ])
        autolayout("H:|-p-[player(>=300)]-p-|")
        autolayout("H:|-p-[startFrame]-(>=p)-[endFrame(==startFrame)]-p-|")
        autolayout("H:|-p-[startLabel][spacerL][posterLabel][spacerR(==spacerL)][endLabel]-p-|")
        autolayout("H:|-p-[play]-p-|")
        autolayout("V:|-p-[player(>=300)]")
        autolayout("V:[player]-p-[play]-(>=0)-[posterLabel]-p-|")
        autolayout("V:[player]-p-[startFrame(==128)][startLabel]-p-|")
        autolayout("V:[player]-p-[endFrame(==startFrame)][endLabel]-p-|")

        if let videoSize = player.currentItem?.naturalSize {
            playerView.addConstraint(NSLayoutConstraint(item: playerView, attribute: .Height, relatedBy: .Equal,
                toItem: playerView, attribute: .Width, multiplier: videoSize.height / videoSize.width, constant: 0))
        }

        if  let asset = player.currentItem?.asset,
            let imageGenerator = AVAssetImageGenerator(asset: asset) as AVAssetImageGenerator?,
            let startImage = imageGenerator.copyImage(at: startTime),
            let endImage = imageGenerator.copyImage(at: endTime) {
                startFrameView.image = startImage
                endFrameView.image = endImage

                startFrameView.addConstraint(NSLayoutConstraint(item: startFrameView, attribute: .Width, relatedBy: .Equal, toItem: startFrameView, attribute: .Height, multiplier: startImage.size.width / startImage.size.height, constant: 0))
        }

        updateLabels()
    }

    @objc private func play() {
        player.seekToTime(startTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player.play()
    }

    @objc private func pause() {
        player.pause()
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch (object, keyPath) {
        case (is AVPlayer, _):
            updatePlayButton()
            break
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}