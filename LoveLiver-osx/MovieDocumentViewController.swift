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
    var createLivePhotoAction: (Void -> Void)?

    weak var movieOverviewViewController: MovieOverviewViewController?

    private let playerView: AVPlayerView = AVPlayerView() ※ { v in
        v.controlsStyle = .Floating
        v.showsFrameSteppingButtons = true
    }
    private lazy var posterFrameButton: NSButton = NSButton() ※ { b in
        b.title = "Live Photo With This Frame"
        b.setButtonType(.MomentaryLightButton)
        b.bezelStyle = .RoundedBezelStyle
        b.target = self
        b.action = #selector(self.createLivePhotoSandbox)
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
        player.pause()
        createLivePhotoAction?()
    }

    // MARK: - AnimeFace
    var animeFaces = [DetectedFace]()
    @IBAction func detectAnimeFace(sender: AnyObject?) {
        animeFaces.removeAll()
        self.movieOverviewViewController?.overview.faceAnnotationView.duration = playerItem.duration
        let animeFace = AnimeFace()

        let detectEachSecs: Double = 0.5
        let times: [CMTime] = 0.stride(to: playerItem.duration.seconds, by: detectEachSecs).map { s in
            CMTime(seconds: s, preferredTimescale: playerItem.duration.timescale)
        }

        let generator = AVAssetImageGenerator(asset: playerItem.asset)
        generator.requestedTimeToleranceBefore = CMTime(seconds: detectEachSecs, preferredTimescale: playerItem.duration.timescale)
        generator.requestedTimeToleranceAfter = generator.requestedTimeToleranceBefore
        generator.generateCGImagesAsynchronouslyForTimes(times.map {NSValue(CMTime: $0)}) { [weak self] (requestedTime, cgImage, actualTime, result, error) -> Void in
            guard let `self` = self else { return }
            guard let cgImage = cgImage where result == .Succeeded else { return }

            let faces = (animeFace.detect(cgImage)).map {$0.rectValue}
            guard !faces.isEmpty else { return }

            dispatch_async(dispatch_get_main_queue()) {
                for f in faces {
                    self.animeFaces.append(DetectedFace(at: actualTime, rect: NSRectToCGRect(f)))
                }
                self.movieOverviewViewController?.overview.faceAnnotationView.faces = self.animeFaces
            }
        }
    }
}
