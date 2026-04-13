import 'dart:async';
import 'package:flutter/material.dart';
import 'ros_manager.dart';

class TapControllerTab extends StatefulWidget {
  final RosManager rosManager;
  final TextEditingController topicController;

  const TapControllerTab({
    super.key,
    required this.rosManager,
    required this.topicController,
  });

  @override
  State<TapControllerTab> createState() => _TapControllerTabState();
}

class _TapControllerTabState extends State<TapControllerTab> {
  Timer? _timer;

  // Current values for linear and angular
  double linearX = 0, linearY = 0, linearZ = 0;
  double angularR = 0, angularP = 0, angularY = 0;

  void _startPublishing(double lx, double ly, double lz,
      double ar, double ap, double ay) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final topic = widget.topicController.text.trim();
      if (topic.isEmpty) return;

      widget.rosManager.publishTwistStamped(topic, {
        "linear": {"x": lx, "y": ly, "z": lz},
        "angular": {"x": ar, "y": ap, "z": ay}
      });
    });
  }

  void _stopPublishing() => _timer?.cancel();

  Widget _controllerButton(String label, double lx, double ly, double lz,
      double ar, double ap, double ay, Color color) {
    return GestureDetector(
      onTapDown: (_) => _startPublishing(lx, ly, lz, ar, ap, ay),
      onTapUp: (_) => _stopPublishing(),
      onTapCancel: () => _stopPublishing(),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: widget.topicController,
            decoration: InputDecoration(
              labelText: 'Topic Name',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _controllerButton('X+', 5, 0, 0, 0, 0, 0, Colors.green.shade400),
              _controllerButton('X-', -5, 0, 0, 0, 0, 0, Colors.green.shade700),
              _controllerButton('Y+', 0, 5, 0, 0, 0, 0, Colors.orange.shade400),
              _controllerButton('Y-', 0, -5, 0, 0, 0, 0, Colors.orange.shade700),
              _controllerButton('Z+', 0, 0, 5, 0, 0, 0, Colors.blue.shade400),
              _controllerButton('Z-', 0, 0, -5, 0, 0, 0, Colors.blue.shade700),
              _controllerButton('R+', 0, 0, 0, 5, 0, 0, Colors.red.shade400),
              _controllerButton('R-', 0, 0, 0, -5, 0, 0, Colors.red.shade700),
              _controllerButton('P+', 0, 0, 0, 0, 5, 0, Colors.purple.shade400),
              _controllerButton('P-', 0, 0, 0, 0, -5, 0, Colors.purple.shade700),
              _controllerButton('Y+', 0, 0, 0, 0, 0, 5, Colors.teal.shade400),
              _controllerButton('Y-', 0, 0, 0, 0, 0, -5, Colors.teal.shade700),
            ],
          ),
        ],
      ),
    );
  }
}
