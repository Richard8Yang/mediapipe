#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class HolisticTracker;
@class HTLandmark;

@protocol TrackerDelegate <NSObject>
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
@end

@interface HolisticTracker : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <TrackerDelegate> delegate;
@end

@interface HTLandmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end
