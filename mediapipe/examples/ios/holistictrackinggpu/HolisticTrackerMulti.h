#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class HolisticTracker;
@class HTLandmark;

@protocol TrackerDelegate <NSObject>
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
@end

@interface HolisticTracker : NSObject
- (instancetype)init: (bool)enableSegmentation enableRefinedFace: (bool)enableIris maxDetectPersons: (int)maxPersons;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <TrackerDelegate> delegate;
@end
