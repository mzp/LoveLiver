//
//  AppDelegate.swift
//  LoveLiver-osx
//
//  Created by BAN Jun on 2016/02/08.
//  Copyright © 2016年 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import NorthLayout
import Ikemen


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let playerView = AVPlayerView() ※ { v in
        v.player = AVPlayer(URL: NSURL(fileURLWithPath: "/path/to/yuubae-portrait-confetti-soft.mov"))
        v.controlsStyle = .Floating
        v.showsFrameSteppingButtons = true
    }
    let posterFrameView = NSImageView() ※ { v in
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

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let contentView = window.contentView {
            let autolayout = contentView.northLayoutFormat(["p": 20], [
                "player": playerView,
                "posterButton": posterFrameButton,
                "posterView": posterFrameView,
                ])
            autolayout("H:|-p-[player]-p-[posterView(==player)]-p-|")
            autolayout("H:|-p-[posterButton(==player)]")
            autolayout("V:|-p-[player]-p-[posterButton]")
            autolayout("V:|-p-[posterView]-p-[posterButton]")
            autolayout("V:[posterButton]-p-|")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
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

