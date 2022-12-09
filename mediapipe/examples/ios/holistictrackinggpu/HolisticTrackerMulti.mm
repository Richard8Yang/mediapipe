#import "HolisticTrackerMulti.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"
#include "mediapipe/framework/formats/classification.pb.h"
static NSString* const kGraphName           = @"multi_holistic_tracking_gpu";
static const char* kInputStream             = "input_video";
static const char* kOutputStream            = "output_video";
static const char* kMultiFaceStream         = "multi_face_landmarks";
static const char* kMultiLeftHandStream     = "multi_left_hand_landmarks";
static const char* kMultiRightHandStream    = "multi_right_hand_landmarks";
static const char* kMultiPoseStream         = "multi_pose_landmarks";
static const char* kMultiPoseWorldStream    = "multi_pose_world_landmarks";

@interface HolisticTracker() <MPPGraphDelegate>
{
}
@property(nonatomic) MPPGraph* mediapipeGraph;
@end

@implementation HolisticTracker {}

#pragma mark - Cleanup methods

- (void)dealloc {
    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource: (NSString*)resource
                enableSegmentation: (bool)enableSeg
                 enableRefinedFace: (bool)enableIris
                  maxDetectPersons: (int)maxPersons {
    // Load the graph config resource.
    NSError* configLoadError = nil;
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    if (!resource || resource.length == 0) {
        return nil;
    }
    NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
    NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
    if (!data) {
        NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
        return nil;
    }
    
    // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
    mediapipe::CalculatorGraphConfig config;
    config.ParseFromArray(data.bytes, data.length);
    
    // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
    MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
    [newGraph setSidePacket:(mediapipe::MakePacket<bool>(enableSeg)) named:"enable_segmentation"];
    [newGraph setSidePacket:(mediapipe::MakePacket<bool>(enableIris)) named:"refine_face_landmarks"];
    [newGraph setSidePacket:(mediapipe::MakePacket<int>(maxPersons)) named:"num_poses"];
    [newGraph setSidePacket:(mediapipe::MakePacket<bool>(false)) named:"smooth_landmarks"];
    [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
    [newGraph addFrameOutputStream:kMultiFaceStream outputPacketType:MPPPacketTypeRaw];
    [newGraph addFrameOutputStream:kMultiLeftHandStream outputPacketType:MPPPacketTypeRaw];
    [newGraph addFrameOutputStream:kMultiRightHandStream outputPacketType:MPPPacketTypeRaw];
    [newGraph addFrameOutputStream:kMultiPoseStream outputPacketType:MPPPacketTypeRaw];
    [newGraph addFrameOutputStream:kMultiPoseWorldStream outputPacketType:MPPPacketTypeRaw];

    return newGraph;
}

- (instancetype)init:(bool)enableSegmentation enableRefinedFace: (bool)enableIris maxDetectPersons: (int)maxPersons {
    self = [super init];
    if (self) {
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName enableSegmentation:enableSegmentation enableRefinedFace:enableIris maxDetectPersons:maxPersons];
        self.mediapipeGraph.delegate = self;
        // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
        self.mediapipeGraph.maxFramesInFlight = 2;
    }
    return self;
}

- (void)startGraph {
    // Start running self.mediapipeGraph.
    NSError* error;
    if (![self.mediapipeGraph startWithError:&error]) {
        NSLog(@"Failed to start graph: %@", error);
    }
}

#pragma mark - MPPGraphDelegate methods

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
    [self.mediapipeGraph sendPixelBuffer:imageBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypePixelBuffer];
}

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
      if (streamName == kOutputStream) {
          [_delegate holisticTracker: self didOutputPixelBuffer: pixelBuffer];
      }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
    if (streamName == kMultiFaceStream || 
        streamName == kMultiLeftHandStream || 
        streamName == kMultiRightHandStream || 
        streamName == kMultiPoseStream || 
        streamName == kMultiPoseWorldStream) {
        // Landmarks array
        if (packet.IsEmpty()) { return; }
        const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
        NSMutableArray<Landmark *> *result = [NSMutableArray array];
        for (int i = 0; i < landmarks.landmark_size(); ++i) {
            Landmark *landmark = [[HTLandmark alloc] initWithX:landmarks.landmark(i).x()
                                                             y:landmarks.landmark(i).y()
                                                             z:landmarks.landmark(i).z()];
            [result addObject:landmark];
        }
        [_delegate holisticTracker: self didOutputLandmarks: result];
    }
}

@end
