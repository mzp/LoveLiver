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

    private lazy var annotationView: AnnotationView = AnnotationView()

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
            "annotation": annotationView,
            ])
        autolayout("H:|[player]|")
        autolayout("H:|[annotation]|")
        autolayout("H:|-p-[posterButton]-p-|")
        autolayout("V:|[player]-p-[posterButton]")
        autolayout("V:|[annotation]-p-[posterButton]")
        autolayout("V:[posterButton]-p-|")
        view.addSubview(annotationView, positioned: .Above, relativeTo: playerView) // TODO: use contentOverlayView of playerView
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
    var playerTimeObserver: AnyObject?
    @IBAction func detectAnimeFace(sender: AnyObject?) {
        let duration = playerItem.duration
        let animeFace = AnimeFace()
        animeFaces.removeAll()
        self.movieOverviewViewController?.overview.faceAnnotationView.duration = playerItem.duration

        let detectEachSecs: Double = 0.1
        let times: [CMTime] = 0.stride(to: duration.seconds, by: detectEachSecs).map { s in
            CMTime(seconds: s, preferredTimescale: duration.timescale)
        }

        let generator = AVAssetImageGenerator(asset: playerItem.asset)
        generator.requestedTimeToleranceBefore = CMTime(seconds: detectEachSecs / 2, preferredTimescale: duration.timescale)
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

        playerTimeObserver = player.addPeriodicTimeObserverForInterval(CMTime(seconds: detectEachSecs, preferredTimescale: duration.timescale), queue: dispatch_get_main_queue()) { [weak self] time in
            guard let `self` = self else { return }
            guard let videoSize = self.playerItem.naturalSize else { return }
            let nearest = self.animeFaces
                .filter {abs($0.at.seconds - time.seconds) <= detectEachSecs} // only near times (exclude scenes without any face)
                .minElement{abs($0.at.seconds - time.seconds) < abs($1.at.seconds - time.seconds)} // find nearest detected time measured by actualTime choosen by the generator
            let faces = nearest.map {nearest in self.animeFaces.filter {$0.at == nearest.at}} ?? []

            // NSLog("%@", "\(faces.count)")

            let scale = self.playerView.videoBounds.width / videoSize.width
            let transform = CGAffineTransformMakeScale(scale, scale)
            self.annotationView.annotations = faces.map { f in
                return (rect: CGRectApplyAffineTransform(f.rect, transform), color: NSColor.greenColor().CGColor)
            }
        }
    }
}


class AnnotationView: NSView {
    var annotations = [(rect: CGRect, color: CGColor)]() {
        didSet {
            setNeedsDisplayInRect((oldValue + annotations).reduce(CGRectNull) {CGRectUnion($0, $1.rect)})
        }
    }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.zPosition = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var flipped: Bool {return true}

    override func drawRect(dirtyRect: NSRect) {
        NSColor.clearColor().set()
        NSRectFill(dirtyRect)

        let context = NSGraphicsContext.currentContext()?.CGContext

        for a in annotations {
            CGContextSetFillColorWithColor(context, a.color)
            NSFrameRectWithWidth(a.rect, 4)
        }
    }
}
