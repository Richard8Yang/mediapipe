#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class HolisticTracker;
@class Landmark;

@protocol TrackerDelegate <NSObject>
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPacket: (const std::string&)name packetData: (NSDictionary *)packet;
@end

@interface HolisticTrackerConfig: NSObject
@property(nonatomic, readonly) bool enableSegmentation;
@property(nonatomic, readonly) bool enableRefinedFace;
@property(nonatomic, readonly) int maxPersonsToTrack;
@property(nonatomic, readonly) bool enableFaceLandmarks;
@property(nonatomic, readonly) bool enablePoseLandmarks;
@property(nonatomic, readonly) bool enableLeftHandLandmarks;
@property(nonatomic, readonly) bool enableRightHandLandmarks;
@property(nonatomic, readonly) bool enableHolisticLandmarks;
@property(nonatomic, readonly) bool enablePoseWorldLandmarks;
@property(nonatomic, readonly) bool enablePixelBufferOutput;

- (void)init: (bool)enableSegmentation
    enableRefinedFace: (bool)enableRefinedFace
    maxPersonsToTrack: (int)maxPersonsToTrack
    enableFaceLandmarks: (bool)enableFaceLandmarks
    enablePoseLandmarks: (bool)enablePoseLandmarks
    enableLeftHandLandmarks: (bool)enableLeftHandLandmarks
    enableRightHandLandmarks: (bool)enableRightHandLandmarks
    enableHolisticLandmarks: (bool)enableHolisticLandmarks
    enablePoseWorldLandmarks: (bool)enablePoseWorldLandmarks
    enablePixelBufferOutput: (bool)enablePixelBufferOutput;
@end

@interface HolisticTracker : NSObject
- (instancetype)init: (HolisticTrackerConfig *)params;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <TrackerDelegate> delegate;
@end

@interface Landmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end
