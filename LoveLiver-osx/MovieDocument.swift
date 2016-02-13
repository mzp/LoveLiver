//
//  MovieDocument.swift
//  LoveLiver
//
//  Created by BAN Jun on 2016/02/09.
//  Copyright © 2016 mzp. All rights reserved.
//

import Cocoa


class MovieDocument: NSDocument {
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        NSLog("%@", "opening \(url)")
    }

    override func makeWindowControllers() {
        let vc = MovieDocumentViewController(movieURL: fileURL!)
        let window = NSWindow(contentViewController: vc)
        let wc = NSWindowController(window: window)
        addWindowController(wc)
    }
}
