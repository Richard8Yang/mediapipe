
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

#include "mediapipe/calculators/util/collection_has_min_size_calculator.h"

#include <vector>

#include "mediapipe/framework/formats/classification.pb.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"

namespace mediapipe {

typedef CollectionHasMinSizeCalculator<std::vector<mediapipe::NormalizedRect>>
    NormalizedRectVectorHasMinSizeCalculator;
REGISTER_CALCULATOR(NormalizedRectVectorHasMinSizeCalculator);

typedef CollectionHasMinSizeCalculator<
    std::vector<mediapipe::NormalizedLandmarkList>>
    NormalizedLandmarkListVectorHasMinSizeCalculator;
REGISTER_CALCULATOR(NormalizedLandmarkListVectorHasMinSizeCalculator);

typedef CollectionHasMinSizeCalculator<
    std::vector<mediapipe::ClassificationList>>
    ClassificationListVectorHasMinSizeCalculator;
REGISTER_CALCULATOR(ClassificationListVectorHasMinSizeCalculator);

typedef MergeByLargerVectorCalculator<
    std::vector<mediapipe::NormalizedRect>>
    MergeByLargerNormalizedRectVectorCalculator;
REGISTER_CALCULATOR(MergeByLargerNormalizedRectVectorCalculator);

// MergeRoiVectorsCalculator
absl::Status MergeRoiVectorsCalculator::GetContract(CalculatorContract* cc) {
    RET_CHECK_EQ(2, cc->Inputs().NumEntries());
    RET_CHECK_EQ(1, cc->Outputs().NumEntries());
    RET_CHECK(cc->Inputs().HasTag("RECTS_FROM_LANDMARKS"));
    RET_CHECK(cc->Inputs().HasTag("RECTS_FROM_DETECTION"));

    cc->Inputs().Tag("RECTS_FROM_LANDMARKS").Set<std::vector<mediapipe::NormalizedRect>>();
    cc->Inputs().Tag("RECTS_FROM_DETECTION").Set<std::vector<mediapipe::NormalizedRect>>();
    cc->Outputs().Index(0).Set<std::vector<mediapipe::NormalizedRect>>();

    return absl::OkStatus();
}

absl::Status MergeRoiVectorsCalculator::Process(CalculatorContext* cc) {
    if (!cc->Inputs().Tag("RECTS_FROM_LANDMARKS").IsEmpty() && !cc->Inputs().Tag("RECTS_FROM_DETECTION").IsEmpty()) {
        const auto& roiVecFromLandmarks = cc->Inputs().Tag("RECTS_FROM_LANDMARKS").Get<std::vector<mediapipe::NormalizedRect>>();
        const auto& roiVecFromDetection = cc->Inputs().Tag("RECTS_FROM_DETECTION").Get<std::vector<mediapipe::NormalizedRect>>();
        if (roiVecFromDetection.size() > roiVecFromLandmarks.size()) {
            cc->Outputs().Index(0).AddPacket(cc->Inputs().Tag("RECTS_FROM_DETECTION").Value());
        } else if (roiVecFromLandmarks.size() == 1) {
            cc->Outputs().Index(0).AddPacket(cc->Inputs().Tag("RECTS_FROM_LANDMARKS").Value());
        } else {
            // Check rois from landmarkd if there are rects that are too close
            // Detect centers of the rects, the diff should be less than 1/100
            const int magnifyCoef = 100;
            std::set<int> uniqueCenters;
            for (const auto& rc : roiVecFromLandmarks) {
                int key = rc.x_center() * magnifyCoef;
                key = (key << 8) + rc.y_center() * magnifyCoef;
                uniqueCenters.insert(key);
            }
            if (uniqueCenters.size() < roiVecFromLandmarks.size()) {
                LOG(WARNING) << "Found same duplicate ROI, new count " << uniqueCenters.size() << " <- " << roiVecFromLandmarks.size();
                cc->Outputs().Index(0).AddPacket(cc->Inputs().Tag("RECTS_FROM_DETECTION").Value());
            } else {
                cc->Outputs().Index(0).AddPacket(cc->Inputs().Tag("RECTS_FROM_LANDMARKS").Value());
            }
        }
    } else if (cc->Inputs().Tag("RECTS_FROM_LANDMARKS").IsEmpty()) {
        cc->Outputs().Index(0).AddPacket(cc->Inputs().Tag("RECTS_FROM_DETECTION").Value());
    } else {
        cc->Outputs().Index(0).AddPacket(cc->Inputs().Tag("RECTS_FROM_LANDMARKS").Value());
    }
    

    return absl::OkStatus();
}

REGISTER_CALCULATOR(MergeRoiVectorsCalculator);

}  // namespace mediapipe
