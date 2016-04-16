//
//  MovieOverviewViewController.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/03/20.
//  Copyright © 2016年 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import NorthLayout


class MovieOverviewViewController: NSViewController {
    let overview: MovieOverviewControl
    
    init(player: AVPlayer, playerItem: AVPlayerItem) {
        self.overview = MovieOverviewControl(player: player, playerItem: playerItem)
        super.init(nibName: nil, bundle: nil)!
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 64))

        let autolayout = view.northLayoutFormat([:], [
            "overview": overview,
            ])
        autolayout("H:|-2-[overview(>=64@999)]-2-|")
        autolayout("V:|[overview]|")
    }

    func movieDidLoad(videoSize: CGSize) {
        overview.currentTime = kCMTimeZero
        overview.reload()
    }
}
