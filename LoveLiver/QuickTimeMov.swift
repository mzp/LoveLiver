
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
    private let kKeyContentIdentifier =  "com.apple.quicktime.content.identifier"
    private let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    private let kKeySpaceQuickTimeMetadata = "mdta"
    private let path : String
    private let dummyTimeRange = CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000))

    private lazy var asset : AVURLAsset = {
        let url = NSURL(fileURLWithPath: self.path)
        return AVURLAsset(URL: url)
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

    func write(dest : String, assetIdentifier : String) {
        do {
            // --------------------------------------------------
            // reader for source video
            // --------------------------------------------------
            guard let track = self.track(AVMediaTypeVideo) else {
                print("not found video track")
                return
            }
            let (reader, output) = try self.reader(track,
                settings: [kCVPixelBufferPixelFormatTypeKey as String:
                    NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)])

            // --------------------------------------------------
            // writer for mov
            // --------------------------------------------------
            let writer = try AVAssetWriter(URL: NSURL(fileURLWithPath: dest), fileType: AVFileTypeQuickTimeMovie)
            writer.metadata = [metadataFor(assetIdentifier)]

            // video track
            let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                outputSettings: videoSettings(track.naturalSize))
            input.expectsMediaDataInRealTime = true
            input.transform = track.preferredTransform
            writer.addInput(input)

            // metadata track
            let adapter = metadataAdapter()
            writer.addInput(adapter.assetWriterInput)

            // --------------------------------------------------
            // creating video
            // --------------------------------------------------
            writer.startWriting()
            reader.startReading()
            writer.startSessionAtSourceTime(kCMTimeZero)

            // write metadata track
            adapter.appendTimedMetadataGroup(AVTimedMetadataGroup(items: [metadataForStillImageTime()],
                timeRange: dummyTimeRange))

            // write video track
            input.requestMediaDataWhenReadyOnQueue(dispatch_queue_create("assetAudioWriterQueue", nil)) {
                while(input.readyForMoreMediaData) {
                    if reader.status == .Reading {
                        if let buffer = output.copyNextSampleBuffer() {
                            if !input.appendSampleBuffer(buffer) {
                                print("cannot write: \(writer.error)")
                                reader.cancelReading()
                            }
                        }
                    } else {
                        input.markAsFinished()
                        writer.finishWritingWithCompletionHandler() {
                            if let e = writer.error {
                                print("cannot write: \(e)")
                            } else {
                                print("finish writing.")
                            }
                        }
                    }
                }
            }
            while writer.status == .Writing {
                NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.5))
            }
            if let e = writer.error {
                print("cannot write: \(e)")
            }
        } catch {
            print("error")
        }
    }

    private func metadata() -> [AVMetadataItem] {
        return asset.metadataForFormat(AVMetadataFormatQuickTimeMetadata)
    }

    private func track(mediaType : String) -> AVAssetTrack? {
        return asset.tracksWithMediaType(mediaType).first
    }

    private func reader(track : AVAssetTrack, settings: [String:AnyObject]?) throws -> (AVAssetReader, AVAssetReaderOutput) {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        let reader = try AVAssetReader(asset: asset)
        reader.addOutput(output)
        return (reader, output)
    }

    private func metadataAdapter() -> AVAssetWriterInputMetadataAdaptor {
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(kKeySpaceQuickTimeMetadata)/\(kKeyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]

        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, [spec], &desc)
        let input = AVAssetWriterInput(mediaType: AVMediaTypeMetadata,
            outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }

    private func videoSettings(size : CGSize) -> [String:AnyObject] {
        return [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
    }

    private func metadataFor(assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyContentIdentifier
        item.keySpace = kKeySpaceQuickTimeMetadata
        item.value = assetIdentifier
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }

    private func metadataForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyStillImageTime
        item.keySpace = kKeySpaceQuickTimeMetadata
        item.value = 0
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
}