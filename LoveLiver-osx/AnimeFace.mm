#import <Foundation/Foundation.h>
#undef check
#import <opencv2/opencv.hpp>
#include <vector>
#import "AnimeFace.h"

@implementation AnimeFace

- (cv::Mat)cvMatFromCGImage:(CGImageRef)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = CGImageGetWidth(image);
    CGFloat rows = CGImageGetHeight(image);

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);
//    CGColorSpaceRelease(colorSpace);

    return cvMat;
}

- (NSArray<NSValue *>*) detect: (CGImageRef)cgImage {
    cv::CascadeClassifier face_cascade;
    NSString* path = [[NSBundle mainBundle] pathForResource:@"lbpcascade_animeface" ofType:@"xml"];
    face_cascade.load([path cStringUsingEncoding:NSUTF8StringEncoding]);

    cv::Mat image = [self cvMatFromCGImage:cgImage];

    cv::Mat gray;
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);

    cv::equalizeHist(gray, gray);

    std::vector<cv::Rect> faces;
    face_cascade.detectMultiScale(gray, faces, 1.1, 3, 0, cv::Size(80,80));

    NSMutableArray<NSValue *>* array = [NSMutableArray array];
    for(int i = 0; i<faces.size(); i++){
        cv::Rect cvRect = faces[i];
        NSRect rect = NSMakeRect(cvRect.x, cvRect.y, cvRect.width, cvRect.height);
        [array addObject: [NSValue valueWithRect: rect]];
    }
    return array;
}
@end
