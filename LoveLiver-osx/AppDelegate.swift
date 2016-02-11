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
    func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
        openDocument(sender)
        return true
    }

    @objc private func openDocument(sender: AnyObject?) {
        NSDocumentController.sharedDocumentController().openDocument(sender)
    }
}

