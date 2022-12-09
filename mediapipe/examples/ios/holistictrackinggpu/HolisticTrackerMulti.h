#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class HolisticTracker;
@class Landmark;

@protocol TrackerDelegate <NSObject>
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPacket: (NSArray<Landmark *> *)packet;
@end

@interface HolisticTracker : NSObject
- (instancetype)init: (bool)enableSegmentation enableRefinedFace: (bool)enableIris maxDetectPersons: (int)maxPersons;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <TrackerDelegate> delegate;
@end

@interface Landmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end
