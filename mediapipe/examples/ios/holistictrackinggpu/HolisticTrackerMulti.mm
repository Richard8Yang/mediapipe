#import "HolisticTrackerMulti.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"
#include "mediapipe/framework/formats/classification.pb.h"

static NSString* const kGraphName   = @"multi_holistic_tracking_gpu";
static const char* kInputStream     = "input_video";
static const char* kOutputStream    = "output_video";
static const int  kHolisticLandmarkTypeCount = 4;

@implementation HolisticTrackerConfig
- (instancetype)init: (bool)enableSegmentation
    enableRefinedFace: (bool)enableRefinedFace
    maxPersonsToTrack: (int)maxPersonsToTrack
    enableFaceLandmarks: (bool)enableFaceLandmarks
    enablePoseLandmarks: (bool)enablePoseLandmarks
    enableLeftHandLandmarks: (bool)enableLeftHandLandmarks
    enableRightHandLandmarks: (bool)enableRightHandLandmarks
    enableHolisticLandmarks: (bool)enableHolisticLandmarks
    enablePoseWorldLandmarks: (bool)enablePoseWorldLandmarks
    enablePixelBufferOutput: (bool)enablePixelBufferOutput {
    self = [super init];
    if (self) {
        _enableSegmentation         = enableSegmentation;
        _enableRefinedFace          = enableRefinedFace;
        _maxPersonsToTrack          = maxPersonsToTrack;
        _enableFaceLandmarks        = enableFaceLandmarks;
        _enablePoseLandmarks        = enablePoseLandmarks;
        _enableLeftHandLandmarks    = enableLeftHandLandmarks;
        _enableRightHandLandmarks   = enableRightHandLandmarks;
        _enableHolisticLandmarks    = enableHolisticLandmarks;
        _enablePoseWorldLandmarks   = enablePoseWorldLandmarks;
        _enablePixelBufferOutput    = enablePixelBufferOutput;
    }
    return self;
}
@end

@interface Landmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@implementation Landmark
- (instancetype)initWithX:(float)x y:(float)y z:(float)z {
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}
@end

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
                    trackingConfig: (HolisticTrackerConfig *)params {
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
    [newGraph setSidePacket:(mediapipe::MakePacket<bool>(params.enableSegmentation)) named:"enable_segmentation"];
    [newGraph setSidePacket:(mediapipe::MakePacket<bool>(params.enableRefinedFace)) named:"refine_face_landmarks"];
    [newGraph setSidePacket:(mediapipe::MakePacket<int>(params.maxPersonsToTrack)) named:"num_poses"];
    [newGraph setSidePacket:(mediapipe::MakePacket<bool>(false)) named:"smooth_landmarks"];
    if (params.enablePixelBufferOutput) {
        [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
    }
    if (params.enableFaceLandmarks) {
        [newGraph addFrameOutputStream:kMultiFaceStream outputPacketType:MPPPacketTypeRaw];
    }
    if (params.enableLeftHandLandmarks) {
        [newGraph addFrameOutputStream:kMultiLeftHandStream outputPacketType:MPPPacketTypeRaw];
    }
    if (params.enableRightHandLandmarks) {
        [newGraph addFrameOutputStream:kMultiRightHandStream outputPacketType:MPPPacketTypeRaw];
    }
    if (params.enablePoseLandmarks) {
        [newGraph addFrameOutputStream:kMultiPoseStream outputPacketType:MPPPacketTypeRaw];
    }
    if (params.enablePoseWorldLandmarks) {
        [newGraph addFrameOutputStream:kMultiPoseWorldStream outputPacketType:MPPPacketTypeRaw];
    }
    if (params.enableHolisticLandmarks) {
        [newGraph addFrameOutputStream:kMultiHolisticStream outputPacketType:MPPPacketTypeRaw];
    }

    return newGraph;
}

- (instancetype)init: (HolisticTrackerConfig *)params {
    self = [super init];
    if (self) {
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName trackingConfig:params];
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
    if (packet.IsEmpty()) { return; }
    if (streamName == kMultiFaceStream || streamName == kMultiPoseStream || 
        streamName == kMultiLeftHandStream || streamName == kMultiRightHandStream) {
        // vector<mediapipe::NormalizedLandmarkList>
        // Returns NSDictionary with index as the key, value of type NSDictionary<NSArray<Landmark>>
        const auto& multiLandmarks = packet.Get<std::vector<::mediapipe::NormalizedLandmarkList>>();
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        for (int idx = 0; idx < multiLandmarks.size(); ++idx) {
            const auto& landmarks = multiLandmarks[idx];
            NSMutableArray<Landmark *> *landmarkArray = [NSMutableArray array];
            for (int i = 0; i < landmarks.landmark_size(); ++i) {
                Landmark *landmark = [[Landmark alloc]  initWithX:landmarks.landmark(i).x()
                                                                y:landmarks.landmark(i).y()
                                                                z:landmarks.landmark(i).z()];
                [landmarkArray addObject:landmark];
                //[landmark release];
            }
            [result setObject:landmarkArray forKey:[NSNumber numberWithInt:idx]];
            //[landmarkArray release];
        }
        NSString *name = [NSString stringWithUTF8String:streamName.c_str()];
        [_delegate holisticTracker: self didOutputLandmarks:name packetData:result];
        [result removeAllObjects];
    } else if (streamName == kMultiHolisticStream) {
        // vector<vector<mediapipe::NormalizedLandmarkList>>
        // Returns NSDictionary with index as the key, value of type NSDictionary<NSDictionary<NSString, NSArray<Landmark>>>
        const auto& multiLandmarks = packet.Get<std::vector<std::vector<::mediapipe::NormalizedLandmarkList>>>();
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        for (int idx = 0; idx < multiLandmarks.size(); ++idx) {
            NSMutableDictionary *holistic = [NSMutableDictionary dictionary];
            const auto& holisticLandmarksArray = multiLandmarks[idx];
            if (holisticLandmarksArray.size() != kHolisticLandmarkTypeCount) {
                NSLog(@"Wrong number (%d) of landmark types for holistic landmarks %d", holisticLandmarksArray.size(), idx);
                continue;
            }
            for (int landmarkTypeIdx = 0; landmarkTypeIdx < holisticLandmarksArray.size(); ++landmarkTypeIdx) {
                const auto& landmarks = holisticLandmarksArray[landmarkTypeIdx];
                NSMutableArray<Landmark *> *landmarkArray = [NSMutableArray array];
                for (int i = 0; i < landmarks.landmark_size(); ++i) {
                    Landmark *landmark = [[Landmark alloc]  initWithX:landmarks.landmark(i).x()
                                                                    y:landmarks.landmark(i).y()
                                                                    z:landmarks.landmark(i).z()];
                    [landmarkArray addObject:landmark];
                    //[landmark release];
                }
                [holistic setObject:landmarkArray forKey:[NSNumber numberWithInt:landmarkTypeIdx]];
                //[landmarkArray release];
            }
            [result setObject:holistic forKey:[NSNumber numberWithInt:idx]];
        }
        NSString *name = [NSString stringWithUTF8String:streamName.c_str()];
        [_delegate holisticTracker: self didOutputLandmarks:name packetData:result];
        [result removeAllObjects];
    } else if (streamName == kMultiPoseWorldStream) {
        // vector<mediapipe::LandmarkList>
        // Returns NSDictionary with index as the key, value of type NSDictionary<NSArray<Landmark>>
        const auto& multiLandmarks = packet.Get<std::vector<::mediapipe::LandmarkList>>();
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        for (int idx = 0; idx < multiLandmarks.size(); ++idx) {
            const auto& landmarks = multiLandmarks[idx];
            NSMutableArray<Landmark *> *landmarkArray = [NSMutableArray array];
            for (int i = 0; i < landmarks.landmark_size(); ++i) {
                Landmark *landmark = [[Landmark alloc]  initWithX:landmarks.landmark(i).x()
                                                                y:landmarks.landmark(i).y()
                                                                z:landmarks.landmark(i).z()];
                [landmarkArray addObject:landmark];
                //[landmark release];
            }
            [result setObject:landmarkArray forKey:[NSNumber numberWithInt:idx]];
            //[landmarkArray release];
        }
        NSString *name = [NSString stringWithUTF8String:streamName.c_str()];
        [_delegate holisticTracker: self didOutputLandmarks:name packetData:result];
        [result removeAllObjects];
    } else {
        // Unsupported stream
    }
}

@end
