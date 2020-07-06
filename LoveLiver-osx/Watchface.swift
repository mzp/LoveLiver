import Foundation

struct Watchface {
    var metadata: Metadata
    struct Metadata: Codable {
    }

    var face: Face
    struct Face: Codable {
    }

    var snapshot: Data
    var no_borders_snapshot: Data
    var device_border_snapshot: Data

    var resources: Resources
    struct Resources {
        var images: Metadata
        var livePhotos: [(mov: QuickTimeMov, jpeg: JPEG, assetIdentifier: String)]

        struct Metadata: Codable {
            var imageList: [Item]
            var version: Int = 1

            struct Item: Codable {
                struct Analysis: Codable {
                    var bgBrightness: Double
                    var bgHue: Double
                    var bgSaturation: Double
                    var coloredText: Bool
                    var complexBackground: Bool
                    var shadowBrightness: Double
                    var shadowHue: Double
                    var shadowSaturation: Double
                    var textBrightness: Double
                    var textHue: Double
                    var textSaturation: Double
                    var version: Int = 1
                }

                var topAnalysis: Analysis
                var leftAnalysis: Analysis
                var bottomAnalysis: Analysis
                var rightAnalysis: Analysis

                var imageURL: String

                var irisDuration: Double = 3
                var irisStillDisplayTime: Double = 0
                var irisVideoURL: String
                var isIris: Bool = true

                var localIdentifier: String?
                var modificationDate: Date = .init()

                var cropH: Int = 480
                var cropW: Int = 384
                var cropX: Int = 0
                var cropY: Int = 0
                var originalCropH: Double
                var originalCropW: Double
                var originalCropX: Double
                var originalCropY: Double
            }
        }

        func fileWrapper(tmpDir: URL) throws -> FileWrapper {
            FileWrapper(directoryWithFileWrappers: try livePhotos.reduce(into: ["Images.plist": FileWrapper(regularFileWithContents: try PropertyListEncoder().encode(images))]) {
                let tmpJpegURL = tmpDir.appendingPathComponent($1.assetIdentifier).appendingPathExtension("jpg")
                let tmpMovURL = tmpDir.appendingPathComponent($1.assetIdentifier).appendingPathExtension("mov")
                $1.jpeg.write(tmpJpegURL.path, assetIdentifier: $1.assetIdentifier)
                $1.mov.write(tmpMovURL.path, assetIdentifier: $1.assetIdentifier)
                $0["\($1.assetIdentifier).jpg"] = FileWrapper(regularFileWithContents: try Data(contentsOf: tmpJpegURL))
                $0["\($1.assetIdentifier).mov"] = FileWrapper(regularFileWithContents: try Data(contentsOf: tmpMovURL))
            })
        }
    }

    func fileWrapper(tmpDir: URL) throws -> FileWrapper {
        FileWrapper(directoryWithFileWrappers: [
            "face.json": FileWrapper(regularFileWithContents: try JSONEncoder().encode(face)),
            "metadata.json": FileWrapper(regularFileWithContents: try JSONEncoder().encode(metadata)),
            "snapshot.png": FileWrapper(regularFileWithContents: snapshot),
            "no_borders_snapshot.png": FileWrapper(regularFileWithContents: no_borders_snapshot),
            "device_border_snapshot.png": FileWrapper(regularFileWithContents: device_border_snapshot),
            "Resources": try resources.fileWrapper(tmpDir: tmpDir)])
    }
}
