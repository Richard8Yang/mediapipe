// Copyright 2019 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <vector>

#include "mediapipe/framework/calculator_framework.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/port/ret_check.h"

namespace mediapipe {

namespace {

constexpr char kLandmarksTag[] = "LANDMARKS";
constexpr char kNormLandmarksTag[] = "NORM_LANDMARKS";

}  // namespace

// Projects world landmarks from the rectangle to original coordinates.
//
// World landmarks are predicted in meters rather than in pixels of the image
// and have origin in the middle of the hips rather than in the corner of the
// pose image (cropped with given rectangle). Thus only rotation (but not scale
// and translation) is applied to the landmarks to transform them back to
// original coordinates.
//
// Input:
//   LANDMARKS: A LandmarkList representing world landmarks in the rectangle.
//
// Output:
//   NORM_LANDMARKS: A NormalizedLandmarkList converted from input LandmarkList
//
// Usage example:
// node {
//   calculator: "LandmarkConvertCalculator"
//   input_stream: "LANDMARKS:landmarks"
//   output_stream: "NORM_LANDMARKS:converted_landmarks"
// }
//
class LandmarkConvertCalculator : public CalculatorBase {
 public:
  static absl::Status GetContract(CalculatorContract* cc) {
    cc->Inputs().Tag(kLandmarksTag).Set<LandmarkList>();
    cc->Outputs().Tag(kNormLandmarksTag).Set<NormalizedLandmarkList>();

    return absl::OkStatus();
  }

  absl::Status Open(CalculatorContext* cc) override {
    cc->SetOffset(TimestampDiff(0));

    return absl::OkStatus();
  }

  absl::Status Process(CalculatorContext* cc) override {
    // Check that landmarks and rect are not empty.
    if (cc->Inputs().Tag(kLandmarksTag).IsEmpty()) {
      return absl::OkStatus();
    }

    const auto& in_landmarks =
        cc->Inputs().Tag(kLandmarksTag).Get<LandmarkList>();

    auto out_landmarks = absl::make_unique<NormalizedLandmarkList>();
    for (int i = 0; i < in_landmarks.landmark_size(); ++i) {
      const auto& in_landmark = in_landmarks.landmark(i);

      NormalizedLandmark* out_landmark = out_landmarks->add_landmark();
      out_landmark->set_x(in_landmark.x());
      out_landmark->set_y(in_landmark.y());
      out_landmark->set_z(in_landmark.z());
      out_landmark->set_visibility(in_landmark.visibility());
      out_landmark->set_presence(in_landmark.presence());
    }

    cc->Outputs()
        .Tag(kNormLandmarksTag)
        .Add(out_landmarks.release(), cc->InputTimestamp());

    return absl::OkStatus();
  }
};
REGISTER_CALCULATOR(LandmarkConvertCalculator);

}  // namespace mediapipe
