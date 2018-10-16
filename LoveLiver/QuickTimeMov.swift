
//
//  QuickTimeMov.swift
//  LoveLiver
//
//  Created by mzp on 10/10/15.
//  Copyright © 2015 mzp. All rights reserved.
//

import Foundation
import AVFoundation

class QuickTimeMov {
    fileprivate let kKeyContentIdentifier =  "com.apple.quicktime.content.identifier"
    fileprivate let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    fileprivate let kKeySpaceQuickTimeMetadata = "mdta"
    fileprivate let path : String
    fileprivate let dummyTimeRange = CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000))

    fileprivate lazy var asset : AVURLAsset = {
        let url = URL(fileURLWithPath: self.path)
        return AVURLAsset(url: url)
    }()

    init(path : String) {
        self.path = path
    }

    func readAssetIdentifier() -> String? {
        for item in metadata() {
            if item.key as? String == kKeyContentIdentifier &&
                item.keySpace == kKeySpaceQuickTimeMetadata {
                return item.value as? String
            }
        }
        return nil
    }

    func readStillImageTime() -> NSNumber? {
        if let track = track(AVMediaTypeMetadata) {
            let (reader, output) = try! self.reader(track, settings: nil)
            reader.startReading()

            while true {
                guard let buffer = output.copyNextSampleBuffer() else { return nil }
                if CMSampleBufferGetNumSamples(buffer) != 0 {
                    let group = AVTimedMetadataGroup(sampleBuffer: buffer)
                    for item in group?.items ?? [] {
                        if item.key as? String == kKeyStillImageTime &&
                            item.keySpace == kKeySpaceQuickTimeMetadata {
                                return item.numberValue
                        }
                    }
                }
            }
        }
        return nil
    }

    func write(_ dest : String, assetIdentifier : String) {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            print("cannot read asset: \(asset.debugDescription)")
            return
        }
        exportSession.outputURL = URL(fileURLWithPath: dest)
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.metadata = [metadataFor(assetIdentifier), metadataForStillImageTime()]
        exportSession.exportAsynchronously {
        }
        while exportSession.status == .exporting || exportSession.status == .waiting {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
        if let e = exportSession.error {
            print("cannot write: \(e)")
        }
    }

    fileprivate func metadata() -> [AVMetadataItem] {
        return asset.metadata(forFormat: AVMetadataFormatQuickTimeMetadata)
    }

    fileprivate func track(_ mediaType : String) -> AVAssetTrack? {
        return asset.tracks(withMediaType: mediaType).first
    }

    fileprivate func reader(_ track : AVAssetTrack, settings: [String:AnyObject]?) throws -> (AVAssetReader, AVAssetReaderOutput) {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        let reader = try AVAssetReader(asset: asset)
        reader.add(output)
        return (reader, output)
    }

    fileprivate func metadataAdapter() -> AVAssetWriterInputMetadataAdaptor {
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(kKeySpaceQuickTimeMetadata)/\(kKeyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]

        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, [spec] as CFArray, &desc)
        let input = AVAssetWriterInput(mediaType: AVMediaTypeMetadata,
            outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }

    fileprivate func videoSettings(_ size : CGSize) -> [String:AnyObject] {
        return [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: size.width as AnyObject,
            AVVideoHeightKey: size.height as AnyObject
        ]
    }

    fileprivate func metadataFor(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = kKeySpaceQuickTimeMetadata
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }

    fileprivate func metadataForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyStillImageTime as (NSCopying & NSObjectProtocol)?
        item.keySpace = kKeySpaceQuickTimeMetadata
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
}
