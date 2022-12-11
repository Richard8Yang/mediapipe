#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

// vector<mediapipe::LandmarkList>
static const char* kMultiPoseWorldStream    = "multi_pose_world_landmarks";

// vector<mediapipe::NormalizedLandmarkList>
static const char* kMultiFaceStream         = "multi_face_landmarks";
static const char* kMultiPoseStream         = "multi_pose_landmarks";
static const char* kMultiLeftHandStream     = "multi_left_hand_landmarks";
static const char* kMultiRightHandStream    = "multi_right_hand_landmarks";

// vector<vector<mediapipe::NormalizedLandmarkList>> in the order of < face->pose->lefthand->righthand > landmarks
static const char* kMultiHolisticStream     = "multi_holistic_landmarks_array";

@class HolisticTracker;
@class Landmark;

@protocol TrackerDelegate <NSObject>
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
- (void)holisticTracker: (HolisticTracker*)holisticTracker didOutputLandmarks: (NSString *)name packetData: (NSDictionary *)packet;
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

- (instancetype)init: (bool)enableSegmentation
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
