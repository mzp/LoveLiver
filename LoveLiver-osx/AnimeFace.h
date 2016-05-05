#import <Foundation/Foundation.h>
#import <CoreGraphics/CGImage.h>

@interface AnimeFace : NSObject
- (NSArray<NSValue *>*) detect: (CGImageRef)cgImage;
@end