//
//  main.swift
//  LoveLiver
//
//  Created by mzp on 10/10/15.
//  Copyright © 2015 mzp. All rights reserved.
//

import Foundation

enum Operation: String {
    case DumpJPEGMetaData = "jpeg"
    case DumpMOVMetaData = "mov"
    case CreateLivePhoto = "livephoto"
}

let cli = CommandLine()
let op = EnumOption<Operation>(shortFlag: "o", longFlag: "operation", required: true,
    helpMessage: "LivePhoto option - jpeg for dump JPEG metadata, mov for dump MOV metadata, livephoto for create LivePhoto")
let image = StringOption(shortFlag: "i", longFlag: "jpeg", required: false,
    helpMessage: "Path to the image file.")
let mov = StringOption(shortFlag: "m", longFlag: "mov", required: false,
    helpMessage: "Path to the mov file.")
let output = StringOption(shortFlag: "o", longFlag: "output", required: false,
    helpMessage: "Path to the output live photo.")

cli.setOptions(op, image, mov, output)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

let kErrorMessage = "no metadata"
switch op.value! {
case Operation.DumpJPEGMetaData:
    if let path = image.value {
        print("asset identifier: \(JPEG(path: path).read() ?? kErrorMessage)")
    } else {
        print("Please specify --jpeg option.")
    }
case Operation.DumpMOVMetaData:
    if let path = mov.value {
        let qt = QuickTimeMov(path: path)
        print("asset identifier: \(qt.readAssetIdentifier() ?? kErrorMessage)")
        print("still image time: \(qt.readStillImageTime() ?? kErrorMessage)")
    } else {
        print("Please specify --mov option.")
    }
case Operation.CreateLivePhoto:
    print("generate livephoto")
}
