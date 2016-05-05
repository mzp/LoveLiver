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
    var overviewVC: MovieOverviewViewController? {
        didSet {
            mainVC?.movieOverviewViewController = overviewVC
        }
    }

    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        NSLog("%@", "opening \(url)")

        playerItem = AVPlayerItem(URL: url)
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
        dispatch_async(dispatch_get_main_queue()) {
            self.waitForMovieLoaded()
        }
    }

    private func waitForMovieLoaded() {
        guard let videoSize = playerItem?.naturalSize else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.waitForMovieLoaded()
            }
            return
        }
        movieDidLoad(videoSize)
    }

    private func movieDidLoad(videoSize: CGSize) {
        overviewVC = MovieOverviewViewController(player: player!, playerItem: playerItem!)
        overviewWindow = NSWindow(contentViewController: overviewVC!) ※ { w in
            w.delegate = self
            w.styleMask = NSResizableWindowMask
        }
        addWindowController(NSWindowController(window: overviewWindow))
        mainWindow!.addChildWindow(overviewWindow!, ordered: .Above)

        mainVC?.movieDidLoad(videoSize)
        overviewVC?.movieDidLoad(videoSize)
        repositionOverviewWindow()
    }

    private func openLivePhotoSandbox() {
        guard let player = player,
            let overviewContentView = overviewVC?.view,
            let overview = overviewVC?.overview else { return }

        let livephotoSandboxVC = LivePhotoSandboxViewController(player: player, baseFilename: fileURL?.lastPathComponent ?? "unknown")
        let popover = NSPopover()
        livephotoSandboxVC.closeAction = {
            popover.performClose(nil)
        }
        popover.behavior = .Semitransient
        popover.contentViewController = livephotoSandboxVC
        popover.showRelativeToRect(overviewContentView.convertRect(overview.currentTimeBar.frame, fromView: overview), ofView: overviewContentView, preferredEdge: NSRectEdge.MinY)
    }

    func windowDidResize(notification: NSNotification) {
        if notification.object === mainWindow {
            repositionOverviewWindow()
        } else if notification.object === overviewWindow {
            repositionMainWindow()
        }
    }

    private var metrics: [String: CGFloat] = [
        "p": 20,
    ]

    private func repositionMainWindow() {
        guard let mainWindow = mainWindow, let overviewWindow = overviewWindow else { return }

        mainWindow.removeChildWindow(overviewWindow)
        mainWindow.setFrameOrigin(NSPoint(
            x: overviewWindow.frame.origin.x - (mainWindow.frame.width - overviewWindow.frame.width) / 2,
            y: overviewWindow.frame.origin.y + overviewWindow.frame.height + metrics["p"]!))
        mainWindow.addChildWindow(overviewWindow, ordered: .Above)
    }

    private func repositionOverviewWindow() {
        guard let mainWindow = mainWindow, let overviewWindow = overviewWindow else { return }

        overviewWindow.setFrameTopLeftPoint(NSPoint(
            x: mainWindow.frame.origin.x + (mainWindow.frame.width - overviewWindow.frame.width) / 2,
            y: mainWindow.frame.origin.y - metrics["p"]!))
    }
}
