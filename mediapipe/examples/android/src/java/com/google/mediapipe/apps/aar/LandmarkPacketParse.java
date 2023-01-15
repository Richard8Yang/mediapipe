
package com.google.mediapipe.apps.aar;

import com.google.mediapipe.framework.Packet;
import com.google.mediapipe.framework.PacketGetter;
import com.google.mediapipe.formats.proto.LandmarkProto.LandmarkList;
import com.google.mediapipe.formats.proto.LandmarkProto.NormalizedLandmarkList;
import java.util.List;

public class LandmarkPacketParse {
  public static List<NormalizedLandmarkList> getNormalizedLandmarkListVector(final Packet packet) {
    return PacketGetter.getProtoVector(packet, NormalizedLandmarkList.parser());
  }

  public static List<List<NormalizedLandmarkList>> getNormalizedLandmarkListVectorVector(final Packet packet) {
    return PacketGetter.getProtoVectorVector(packet, NormalizedLandmarkList.parser());
  }

  public static List<LandmarkList> getLandmarkListVector(final Packet packet) {
    return PacketGetter.getProtoVector(packet, LandmarkList.parser());
  }

  public static List<List<LandmarkList>> getLandmarkListVectorVector(final Packet packet) {
    return PacketGetter.getProtoVectorVector(packet, LandmarkList.parser());
  }
}
