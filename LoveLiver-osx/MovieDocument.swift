//
//  MovieDocument.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/02/09.
//  Copyright © 2016 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import Ikemen


class MovieDocument: NSDocument, NSWindowDelegate {
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var mainWindow: NSWindow?
    var mainVC: MovieDocumentViewController?
    var overviewWindow: NSWindow?
    var overviewVC: MovieOverviewViewController?

    override func read(from url: URL, ofType typeName: String) throws {
        NSLog("%@", "opening \(url)")

        playerItem = AVPlayerItem(url: url)
        guard let playerItem = playerItem else { throw NSError(domain: "MovieDocument", code: 0, userInfo: [:]) }
        player = AVPlayer(playerItem: playerItem)
    }

    override func makeWindowControllers() {
        mainVC = MovieDocumentViewController(movieURL: fileURL!, playerItem: playerItem!, player: player!)
        mainVC?.createLivePhotoAction = {[weak self] in self?.openLivePhotoSandbox()}
        mainWindow = NSWindow(contentViewController: mainVC!) ※ { w in
            w.delegate = self
        }
        addWindowController(NSWindowController(window: mainWindow) ※ { wc in
            wc.shouldCloseDocument = true
            })
        windowControllers.forEach { wc in
            wc.showWindow(nil)
        }
        DispatchQueue.main.async {
            self.waitForMovieLoaded()
        }
    }

    fileprivate func waitForMovieLoaded() {
        guard let videoSize = playerItem?.naturalSize, playerItem?.duration.isIndefinite == false else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.waitForMovieLoaded()
            }
            return
        }
        movieDidLoad(videoSize)
    }

    fileprivate func movieDidLoad(_ videoSize: CGSize) {
        overviewVC = MovieOverviewViewController(player: player!, playerItem: playerItem!)
        overviewWindow = NSWindow(contentViewController: overviewVC!) ※ { w in
            w.delegate = self
            w.styleMask = .resizable
        }
        addWindowController(NSWindowController(window: overviewWindow))
        mainWindow!.addChildWindow(overviewWindow!, ordered: .above)

        mainVC?.movieDidLoad(videoSize)
        overviewVC?.movieDidLoad(videoSize)
        repositionOverviewWindow()
    }

    fileprivate func openLivePhotoSandbox() {
        guard let player = player,
            let overviewContentView = overviewVC?.view,
            let overview = overviewVC?.overview else { return }

        let livephotoSandboxVC = LivePhotoSandboxViewController(player: player, baseFilename: fileURL?.lastPathComponent ?? "unknown")
        let popover = NSPopover()
        livephotoSandboxVC?.closeAction = {
            popover.performClose(nil)
        }
        popover.behavior = .semitransient
        popover.contentViewController = livephotoSandboxVC
        popover.show(relativeTo: overviewContentView.convert(overview.currentTimeBar.frame, from: overview), of: overviewContentView, preferredEdge: NSRectEdge.minY)
    }

    func windowDidResize(_ notification: Notification) {
        if let object = notification.object as? NSWindow {
            if object === mainWindow {
                repositionOverviewWindow()
            } else if object === overviewWindow {
                repositionMainWindow()
            }
        }
    }

    fileprivate var metrics: [String: CGFloat] = [
        "p": 20,
    ]

    fileprivate func repositionMainWindow() {
        guard let mainWindow = mainWindow, let overviewWindow = overviewWindow else { return }

        mainWindow.removeChildWindow(overviewWindow)
        mainWindow.setFrameOrigin(NSPoint(
            x: overviewWindow.frame.origin.x - (mainWindow.frame.width - overviewWindow.frame.width) / 2,
            y: overviewWindow.frame.origin.y + overviewWindow.frame.height + metrics["p"]!))
        mainWindow.addChildWindow(overviewWindow, ordered: .above)
    }

    fileprivate func repositionOverviewWindow() {
        guard let mainWindow = mainWindow, let overviewWindow = overviewWindow else { return }

        overviewWindow.setFrameTopLeftPoint(NSPoint(
            x: mainWindow.frame.origin.x + (mainWindow.frame.width - overviewWindow.frame.width) / 2,
            y: mainWindow.frame.origin.y - metrics["p"]!))
    }
}
