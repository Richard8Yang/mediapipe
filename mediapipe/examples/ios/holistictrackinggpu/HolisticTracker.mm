#import "HolisticTracker.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"
#include "mediapipe/framework/formats/classification.pb.h"
//static NSString* const kGraphName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GraphName"];//@"hand_tracking_mobile_gpu";
//static const char* kInputStream = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GraphInputStream"];//"input_video";
//static const char* kOutputStream = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GraphOutputStream"];//"output_video";
//static const char* kCameraFacing = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CameraPosition"];
static NSString* const kGraphName = @"holistic_tracking_gpu";
static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
//static const char* kRectOutputStream = "hand_rect_from_landmarks";
//static const char* kLandmarksOutputStream = "hand_landmarks";
//static const char* kHandednessOutputStream = "handedness";
//static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";

@interface HolisticTracker() <MPPGraphDelegate>
{
}
@property(nonatomic) MPPGraph* mediapipeGraph;
@end

@interface HTLandmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
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

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource {
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
    [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
    //[newGraph addFrameOutputStream:kLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
    //[newGraph addFrameOutputStream:kRectOutputStream outputPacketType:MPPPacketTypeRaw];
    //[newGraph addFrameOutputStream:kHandednessOutputStream outputPacketType:MPPPacketTypeRaw];

    return newGraph;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
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
    /*if (streamName == kLandmarksOutputStream) {
        if (packet.IsEmpty()) { return; }
        const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
                
        NSMutableArray<HTLandmark *> *result = [NSMutableArray array];
        
        for (int i = 0; i < landmarks.landmark_size(); ++i) {
            HTLandmark *landmark = [[HTLandmark alloc] initWithX:landmarks.landmark(i).x()
                                                             y:landmarks.landmark(i).y()
                                                             z:landmarks.landmark(i).z()];
            [result addObject:landmark];
        }
        if (!CGSizeEqualToSize(lastHandSize, CGSizeZero) && self.currentHandedness != HTHandednessUnknown) {
            HTHandInfo *info = [[HTHandInfo alloc] initWithLandmarks:result.copy andHandSize:lastHandSize andIsRightHand:self.currentHandedness == HTHandednessRight andHandednessScore:self.currentHandedness];
            
            [_delegate holisticTracker:self didOutputHandInfo:info];
        }
    }*/
}

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
    [self.mediapipeGraph sendPixelBuffer:imageBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypePixelBuffer];
}

@end

@implementation HTLandmark

- (instancetype)initWithX:(float)x y:(float)y z:(float)z
{
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}

@end
