import 'dart:async';
import 'package:flutter/material.dart';
import 'ros_manager.dart';

class JoystickTab extends StatefulWidget {
  final RosManager rosManager;
  final TextEditingController topicController;

  const JoystickTab({super.key, required this.rosManager, required this.topicController});

  @override
  State<JoystickTab> createState() => _JoystickTabState();
}

class _JoystickTabState extends State<JoystickTab> {
  Timer? _timer;

  void _startPublishing(double lin, double ang) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final topic = widget.topicController.text.trim();
      if (topic.isEmpty) return;
      widget.rosManager.publishTwistStamped(topic, {
        "linear": {"x": lin.toDouble(), "y": 0, "z": 0},
        "angular": {"x": 0, "y": 0, "z": ang.toDouble()}
      });
    });
  }

  void _stopPublishing() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Tap X or Y to move', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTapDown: (_) => _startPublishing(1, 0),
                onTapUp: (_) => _stopPublishing(),
                child: Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.green.shade300, borderRadius: BorderRadius.circular(16)),
                  child: const Text('X', style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTapDown: (_) => _startPublishing(0, 1),
                onTapUp: (_) => _stopPublishing(),
                child: Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.orange.shade300, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Y', style: TextStyle(fontSize: 24, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
