import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class RosManager {
  WebSocketChannel? _channel;
  final Set<String> _advertisedTopics = {};

  bool get isConnected => _channel != null;

  void connect(String uri) {
    _channel = WebSocketChannel.connect(Uri.parse(uri));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _advertisedTopics.clear();
  }

  void advertise(String topic, String type) {
    if (_channel == null || _advertisedTopics.contains(topic)) return;

    final payload = {
      "op": "advertise",
      "topic": topic,
      "type": type,
    };

    _channel!.sink.add(jsonEncode(payload));
    _advertisedTopics.add(topic);
  }

  /// Publish PoseStamped (Standard for AR Position + Orientation)
  void publishPoseStamped(String topic, Map<String, dynamic>  poseMsg) {
    if (_channel == null) return;

    // 1. Advertise as the correct standard type
    advertise(topic, "geometry_msgs/PoseStamped");

    // 2. Wrap in the rosbridge protocol format
    final payload = {
      "op": "publish",
      "topic": topic,
      "type": "geometry_msgs/PoseStamped",
      "msg": poseMsg,
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Generic publish method
  void publish(String topic, dynamic msg, String type) {
    if (_channel == null) return;

    // Advertise if not done
    advertise(topic, type);

    // For std_msgs/* wrap in {"data": ...}, otherwise send structure directly
    final payload = {
      "op": "publish",
      "topic": topic,
      "type": type,
      "msg": type.startsWith("std_msgs/") ? {"data": msg} : msg,
    };

    _channel!.sink.add(jsonEncode(payload));
  }
  
  /// Publish a simple String message
  void publishStdString(String topic, String data) {
    if (_channel == null) return;

    const String type = "std_msgs/msg/String";
    advertise(topic, type);

    final payload = {
      "op": "publish",
      "topic": topic,
      "type": type,
      "msg": {"data": data},
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// NEW: Publish an Int32MultiArray for volume feedback [Up, Down]
  /// Publish an Int32MultiArray for volume toggle states [UpState, DownState]
  void publishInt32MultiArray(String topic, List<int> data) {
    if (_channel == null) return;

    const String type = "std_msgs/msg/Int32MultiArray";
    advertise(topic, type);

    final msg = {
      "layout": {
        "dim": [],
        "data_offset": 0,
      },
      "data": data, 
    };

    final payload = {
      "op": "publish",
      "topic": topic,
      "type": type,
      "msg": msg,
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Publish TwistStamped
  void publishTwistStamped(String topic, Map<String, dynamic> twist) {
    if (_channel == null) return;

    advertise(topic, "geometry_msgs/TwistStamped");

    final payload = {
      "op": "publish",
      "topic": topic,
      "type": "geometry_msgs/TwistStamped",
      "msg": {"twist": twist},
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Publish Vector3Stamped
  void publishVector3Stamped(String topic, Map<String, dynamic> vector) {
    if (_channel == null) return;

    advertise(topic, "geometry_msgs/Vector3Stamped");

    final payload = {
      "op": "publish",
      "topic": topic,
      "type": "geometry_msgs/Vector3Stamped",
      "msg": vector, // Send full structure directly
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  /// Publish NavSatFix
  void publishNavSatFix(String topic, Map<String, dynamic> navsat) {
    if (_channel == null) return;

    advertise(topic, "sensor_msgs/NavSatFix");

    final payload = {
      "op": "publish",
      "topic": topic,
      "type": "sensor_msgs/NavSatFix",
      "msg": navsat,
    };

    _channel!.sink.add(jsonEncode(payload));
  }
}