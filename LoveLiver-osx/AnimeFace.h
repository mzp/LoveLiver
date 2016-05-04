#import <Foundation/Foundation.h>
#import <CoreGraphics/CGImage.h>

@interface AnimeFace : NSObject
- (NSArray*) detect: (CGImageRef)cgImage;
@end