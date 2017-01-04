//
//  TouchbarController.swift
//
//
//  Created by mzp on 2016/12/10.
//
//

import Foundation
import Cocoa
import AVFoundation
import NorthLayout
import Ikemen

protocol OverviewTouchBarItemProviderType : class {
    var shouldUpdateScopeRange: ((_ newValue: CMTimeRange?) -> Bool)? { get set }
    var onScopeChange: ((_ overview : MovieOverviewControl) -> Void)? { get set }
    var trimRange : CMTimeRange { get set }
    var scopeRange : CMTimeRange { get set }
    var dragging : Bool { get }

    @available(OSX 10.12.2, *)
    func makeTouchbarItem(identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem
}

@available(OSX 10.12.2, *)
class OverviewTouchBarItemProvider : NSViewController, OverviewTouchBarItemProviderType {
    var shouldUpdateScopeRange: ((_ newValue: CMTimeRange?) -> Bool)?
    var onScopeChange: ((_ overview : MovieOverviewControl) -> Void)?
    var trimRange : CMTimeRange = kCMTimeRangeZero {
        didSet {
            overview.trimRange = trimRange
        }
    }
    var scopeRange : CMTimeRange = kCMTimeRangeZero {
        didSet {
            overview.scopeRange = scopeRange
        }
    }

    private(set) var dragging = false

    private let overview: MovieOverviewControl

    init(player: AVPlayer, playerItem: AVPlayerItem) {
        self.overview = MovieOverviewControl(player: player, playerItem: playerItem)
        self.overview.draggingMode = .scope
        self.overview.imageGeneratorTolerance = kCMTimeZero
        super.init(nibName: nil, bundle: nil)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func makeTouchbarItem(identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem {
        return NSCustomTouchBarItem(identifier: identifier) ※ { item in
            item.viewController = self
        }
    }

    override func loadView() {
        self.view = NSView()
        let autolayout = view.northLayoutFormat([:], [
            "overview": overview,
            ])
        autolayout("H:|[overview]|")
        autolayout("V:|[overview]|")
    }

    override func viewDidAppear() {
        self.overview.reload()
    }

    override func touchesBegan(with theEvent: NSEvent) {
        if let touch = theEvent.touches(matching: .began, in: view).first, touch.type == .direct {
            dragging = true
            seekToTouchPosition(touch)
        }

    }

    override func touchesMoved(with theEvent: NSEvent) {
        if let touch = theEvent.touches(matching: .moved, in: overview).first {
            seekToTouchPosition(touch)
        }
    }

    override func touchesEnded(with theEvent: NSEvent) {
        if let touch = theEvent.touches(matching: .ended, in: overview).first {
            dragging = false
            seekToTouchPosition(touch)
        }
    }

    private func seekToTouchPosition(_ touch: NSTouch) {
        let trimRange = overview.trimRange
        let duration = overview.scopeRange?.duration ?? kCMTimeZero

        let p = view.convert(touch.location(in: view), from: nil)

        let touchTime = CMTimeAdd(trimRange.start, CMTime(value: Int64(CGFloat(trimRange.duration.value) * p.x / view.bounds.width), timescale: trimRange.duration.timescale))
        let maxStart = CMTimeSubtract(trimRange.end, duration)
        let start = CMTimeMinimum(touchTime, maxStart)

        let end = CMTimeAdd(start, duration)
        let newScopeRange = CMTimeRange(start: start, end: end)

        if shouldUpdateScopeRange?(newScopeRange) == true {
            overview.scopeRange = newScopeRange
            onScopeChange?(overview)
        }
    }
}
