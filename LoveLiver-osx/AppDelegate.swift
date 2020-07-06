//
//  AppDelegate.swift
//  LoveLiver-osx
//
//  Created by BAN Jun on 2016/02/08.
//  Copyright © 2016 mzp. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import NorthLayout
import Ikemen


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        openDocument(sender)
        return true
    }

    @objc private func openDocument(_ sender: AnyObject?) {
        NSDocumentController.shared.openDocument(sender)
    }
}

