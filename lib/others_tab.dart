import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:web_socket_channel/status.dart';
import 'ros_manager.dart';
import 'package:volume_controller/volume_controller.dart'; 

class OthersTab extends StatefulWidget {
  final RosManager rosManager;
  const OthersTab({super.key, required this.rosManager});

  @override
  State<OthersTab> createState() => _OthersTabState();
}

class _OthersTabState extends State<OthersTab> with WidgetsBindingObserver {
  bool _arPublishing = false;
  ARSessionManager? _arSessionManager;
  Timer? _arPollTimer;
  double _lastVolume=0.0;
  bool _volMonitorActive = false;
  
  // Separate controllers for separate topics
  final TextEditingController _arTopicController = TextEditingController(text: 'ar_pose'); 
  final TextEditingController _volTopicController = TextEditingController(text: 'volume'); 
  
  int _upToggle = 0;
  int _downToggle = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VolumeController.instance.getVolume().then((v) => _lastVolume = v);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAr(); 
    _stopVolumeMonitor(); 
    _arTopicController.dispose();
    _volTopicController.dispose();
    super.dispose();
  }

  void _stopAr() {
    _arPollTimer?.cancel();
    _arPollTimer = null;
    _arSessionManager?.dispose();
    _arSessionManager = null;
  }

  // --- AR Pose (XYZ + Quaternion) Logic ---
  Future<void> _pollArPose() async {
    if (_arSessionManager == null || !widget.rosManager.isConnected) return;
    try {
      Matrix4? poseMatrix = await _arSessionManager!.getCameraPose();
      if (poseMatrix == null) return;

      // 1. Extract Position (XYZ)
      final vector.Vector3 translation = poseMatrix.getTranslation();
      
      // 2. Extract Orientation as a Quaternion
      final vector.Quaternion q = vector.Quaternion.fromRotation(poseMatrix.getRotation());

      // 3. Publish using the custom topic name from the controller
      final String topicSuffix = _arTopicController.text.trim();
      final String fullTopic = topicSuffix.startsWith('/') ? topicSuffix : '/Phone2Act/$topicSuffix';

      widget.rosManager.publishPoseStamped(fullTopic, {
        "header": {
          "stamp": {
            "sec": DateTime.now().millisecondsSinceEpoch ~/ 1000,
            "nanosec": (DateTime.now().microsecondsSinceEpoch % 1000000) * 1000
          },
          "frame_id": "phone_ar_frame"
        },
        "pose": {
          "position": {
            "x": translation.x,
            "y": translation.y,
            "z": translation.z
          },
          "orientation": {
            "x": q.x,
            "y": q.y,
            "z": q.z,
            "w": q.w
          }
        }
      });
    } catch (e) {
      debugPrint("AR Error: $e");
    }
  }

  // --- Volume Toggle Logic ---
 void _startVolumeMonitor() {
  VolumeController.instance.showSystemUI = false;
  VolumeController.instance.addListener((double val) {
    if (!mounted || !widget.rosManager.isConnected) return;

    setState(() {
      
       if (val > _lastVolume) {
        _upToggle = (_upToggle == 0) ? 1 : 0;
        _lastVolume = val;
        
      } 
      else if (val < _lastVolume) {
        _downToggle = (_downToggle == 0) ? 1 : 0;
         _lastVolume = val;
      }
    });

    // 3. Publish to ROS2
    final String volSuffix = _volTopicController.text.trim();
    final String fullVolTopic = volSuffix.startsWith('/') ? volSuffix : '/Phone2Act/$volSuffix';
    widget.rosManager.publishInt32MultiArray(fullVolTopic, [_upToggle, _downToggle]);
  });
}

  void _stopVolumeMonitor() {
    VolumeController.instance.removeListener();
    if (mounted) {
      setState(() {
        _upToggle = 0;
        _downToggle = 0;
        _volMonitorActive = false;
      });
    }
  }

  void _toggleVolumeMonitor() {
    setState(() {
      _volMonitorActive = !_volMonitorActive;
      if (_volMonitorActive) {
        _startVolumeMonitor();
      } else {
        _stopVolumeMonitor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _arTopicController, 
                decoration: const InputDecoration(
                  labelText: 'AR Pose Topic',
                  hintText: 'e.g. ar_pose',
                  prefixText: '/Phone2Act/',
                  border: OutlineInputBorder(),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _volTopicController, 
                decoration: const InputDecoration(
                  labelText: 'Volume Topic',
                  hintText: 'e.g. volume',
                  prefixText: '/Phone2Act/',
                  border: OutlineInputBorder(),
                )
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2, padding: const EdgeInsets.all(16), 
            mainAxisSpacing: 16, crossAxisSpacing: 16,
            children: [
              _box('AR Pose\n(XYZ + Quat)', Colors.purple, _arPublishing, () {
                if (_arPublishing) { 
                  _stopAr(); 
                  setState(() => _arPublishing = false); 
                } else { 
                  setState(() => _arPublishing = true); 
                }
              }),
              _box('Vol Toggle\n($_upToggle, $_downToggle)', Colors.orange, _volMonitorActive, _toggleVolumeMonitor),
            ],
          ),
        ),
        if (_arPublishing) 
          SizedBox(
            width: 1, 
            height: 1, 
            child: Visibility(
              visible: false, 
              maintainState: true, 
              child: ARView(onARViewCreated: (sm, om, am, lm) {
                _arSessionManager = sm;
                _arSessionManager!.onInitialize(showFeaturePoints: false);
                _arPollTimer = Timer.periodic(const Duration(milliseconds: 20), (_) => _pollArPose());
              })
            )
          ),
      ],
    );
  }

  Widget _box(String txt, Color col, bool active, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? col.withOpacity(0.5) : col, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))]
        ),
        child: Center(
          child: Text(
            txt, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), 
            textAlign: TextAlign.center
          )
        ),
      ),
    );
  }
}