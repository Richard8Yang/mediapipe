/**
 * Copyright 2022 The MediaPipe Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Placeholder for internal dependency on trusted resource url

/** Options to configure MediaPipe Tasks in general. */
export interface BaseOptions {
  /**
   * The model path to the model asset file. Only one of `modelAssetPath` or
   * `modelAssetBuffer` can be set.
   */
  modelAssetPath?: string|undefined;

  /**
   * A buffer containing the model aaset. Only one of `modelAssetPath` or
   * `modelAssetBuffer` can be set.
   */
  modelAssetBuffer?: Uint8Array|undefined;

  /** Overrides the default backend to use for the provided model. */
  delegate?: 'cpu'|'gpu'|undefined;
}
