import Foundation

struct Watchface {
    var metadata: Metadata
    struct Metadata: Codable {
        var version: Int = 1
        var device_size = 2 // 38mm, 42mm?

        var complication_sample_templates: ComplicationSampleTemplate
        struct ComplicationSampleTemplate: Codable {
            var top: String? // base64 joined with \r\n of archived CLKComplicationTemplate data by NSKeyedArchiver
            var bottom: String?

            /// (nil, nil) should work
            init(top: CLKComplicationTemplateUtilitarianSmallFlat?, bottom: CLKComplicationTemplateUtilitarianSmallFlat?) {
                self.top = top.map {NSKeyedArchiver.archivedData(withRootObject: $0).base64EncodedString()}
                self.bottom = bottom.map {NSKeyedArchiver.archivedData(withRootObject: $0).base64EncodedString()}
            }

            @objc(CLKComplicationTemplate)
            class CLKComplicationTemplate: NSObject, NSCoding {
                override init() {
                    super.init()
                }
                required init?(coder: NSCoder) {
                }
                func encode(with coder: NSCoder) {
                }
            }

            @objc(CLKComplicationTemplateUtilitarianSmallFlat)
            final class CLKComplicationTemplateUtilitarianSmallFlat: CLKComplicationTemplate {
                var creationDate: NSDate = .init()
                var finalized: Bool = true
                var imageProvider: NSObject? = nil
                var linkedOnOrAfterGrace: Bool = false
                var metadata: NSObject? = nil
                var sensitivity: Int = 0
                var textProvider: CLKDateTextProvider? = .init()
                var tintColor: NSObject? = nil

                override init() {
                    super.init()
                }
                required init?(coder: NSCoder) {
                    self.textProvider = coder.decodeObject(forKey: "textProvider") as? CLKDateTextProvider
                    super.init(coder: coder)
                }
                override func encode(with coder: NSCoder) {
                    super.encode(with: coder)
                    coder.encode(creationDate, forKey: "creationDate")
                    coder.encode(finalized, forKey: "finalized")
                    coder.encode(imageProvider, forKey: "imageProvider")
                    coder.encode(linkedOnOrAfterGrace, forKey: "linkedOnOrAfterGrace")
                    coder.encode(metadata, forKey: "metadata")
                    coder.encode(sensitivity, forKey: "sensitivity")
                    coder.encode(textProvider, forKey: "textProvider")
                    coder.encode(tintColor, forKey: "tintColor")
                }
            }

            @objc(CLKTextProvider)
            class CLKTextProvider: NSObject, NSCoding {
                override init() {
                    super.init()
                }
                required init?(coder: NSCoder) {
                }
                func encode(with coder: NSCoder) {
                }
            }

            @objc(CLKDateTextProvider)
            final class CLKDateTextProvider: CLKTextProvider {
                var _accessibility: NSObject? = nil
                var _allowsNarrowUnits: Bool = false
                var _alternateCalendarLocaleID: NSObject? = nil
                var _calendarUnits: Int = 528
                var _date: NSDate = .init()
                var _formattingContext: Int = 2
                var _narrowStandaloneWeekdayDay: Bool = false
                var _shortUnits: Bool = true
                var _timeZone: NSObject? = nil
                var _uppercase: Bool = true
                var finalized: Bool = true
                var ignoreUppercaseStyle: Bool = false
                var italicized: Bool = false
                var monospacedNumbers: Bool = false
                var shrinkTextPreference: Bool = false
                var tintColor: NSObject? = nil
                var updateFrequency: Int = 0

                override init() {
                    super.init()
                }
                required init?(coder: NSCoder) {
                    super.init(coder: coder)
                }
                override func encode(with coder: NSCoder) {
                    super.encode(with: coder)
                    coder.encode(_accessibility, forKey: "_accessibility")
                    coder.encode(_allowsNarrowUnits, forKey: "_allowsNarrowUnits")
                    coder.encode(_alternateCalendarLocaleID, forKey: "_alternateCalendarLocaleID")
                    coder.encode(_calendarUnits, forKey: "_calendarUnits")
                    coder.encode(_date, forKey: "_date")
                    coder.encode(_formattingContext, forKey: "_formattingContext")
                    coder.encode(_narrowStandaloneWeekdayDay, forKey: "_narrowStandaloneWeekdayDay")
                    coder.encode(_shortUnits, forKey: "_shortUnits")
                    coder.encode(_timeZone, forKey: "_timeZone")
                    coder.encode(_uppercase, forKey: "_uppercase")
                    coder.encode(finalized, forKey: "finalized")
                    coder.encode(ignoreUppercaseStyle, forKey: "ignoreUppercaseStyle")
                    coder.encode(italicized, forKey: "italicized")
                    coder.encode(monospacedNumbers, forKey: "monospacedNumbers")
                    coder.encode(shrinkTextPreference, forKey: "shrinkTextPreference")
                    coder.encode(tintColor, forKey: "tintColor")
                    coder.encode(updateFrequency, forKey: "updateFrequency")
                }
            }
        }

        var complications_names: ComplicationsNames
        struct ComplicationsNames: Codable {
            var top: String = "Off"
            var bottom: String = "Off"
        }

        var complications_item_ids: ComplicationsItemIDs
        struct ComplicationsItemIDs: Codable {
        }
    }

    var face: Face
    struct Face: Codable {
        var version: Int = 4
        var customization: Customization
        struct Customization: Codable {
            var color: String = "none"
            var content: String = "custom"
            var position: String = "top"
        }

        var face_type: String = "photos"
        var resource_directory: Bool = true

        var complications: Complications?
        struct Complications: Codable {
            var top: Item? = Item()
            struct Item: Codable {
                var app: String = "date"
            }
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case customization
            case complications
            case face_type = "face type"
            case resource_directory = "resource directory"
        }
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

                /// required for watchface sharing... it seems like PHAsset local identifier "UUID/L0/001". an empty string should work anyway.
                var localIdentifier: String
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
