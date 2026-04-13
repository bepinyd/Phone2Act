import 'dart:async';
import 'package:flutter/material.dart';
import 'ros_manager.dart';
import 'tap_controller_tab.dart';

class PublisherPage extends StatefulWidget {
  final RosManager rosManager;
  final bool isJoystick;

  const PublisherPage({super.key, required this.rosManager, this.isJoystick = false});

  @override
  State<PublisherPage> createState() => _PublisherPageState();
}

class _PublisherPageState extends State<PublisherPage> with SingleTickerProviderStateMixin {
  final _topicController = TextEditingController();
  final _messageController = TextEditingController();
  final _msgTypeController = TextEditingController();
  bool _isPublishing = false;
  Timer? _timer;

  late TabController _tabController;

  final _commonTypes = [
    'std_msgs/msg/String',
    'std_msgs/msg/Int32',
    'std_msgs/msg/Float32',
    'std_msgs/msg/Bool',
    'geometry_msgs/msg/TwistStamped'
  ];

  // Slider joystick variables
  double x = 0, y = 0, z = 0, roll = 0, pitch = 0, yaw = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _publishOnce() {
    final rawTopic = _topicController.text.trim();
    if (rawTopic.isEmpty) return;
    final topic = rawTopic.startsWith('/bros2/') ? rawTopic : '/bros2/$rawTopic';

    if (widget.isJoystick && _tabController.index == 0) {
      final twist = {
        "linear": {"x": x, "y": y, "z": z},
        "angular": {"x": roll, "y": pitch, "z": yaw}
      };
      widget.rosManager.publishTwistStamped(topic, twist);
    } else if (!widget.isJoystick) {
      final msg = _messageController.text;
      final type = _msgTypeController.text.trim();
      if (msg.isEmpty || type.isEmpty) return;
      widget.rosManager.publish(topic, msg, type);
    }
  }

  void _startStopPublishing() {
    if (_isPublishing) {
      _timer?.cancel();
      setState(() => _isPublishing = false);
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _publishOnce());
      setState(() => _isPublishing = true);
    }
  }

  Widget _commonTopicUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              labelText: 'Topic Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.blue.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(onPressed: _publishOnce, child: const Text('Publish Once')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _startStopPublishing,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _isPublishing ? Colors.red : Colors.blue),
                child: Text(_isPublishing ? 'Stop Publishing' : 'Start Publishing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customMessageUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _commonTopicUI(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Message Type"),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _commonTypes.contains(_msgTypeController.text)
                      ? _msgTypeController.text
                      : null,
                  hint: const Text('Select Msg Type'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                  items: _commonTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => _msgTypeController.text = value ?? '',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgTypeController,
                  decoration: InputDecoration(
                    labelText: 'Or Custom Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderJoystickUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _axisSlider('Linear X', x, (val) => setState(() => x = val)),
          _axisSlider('Linear Y', y, (val) => setState(() => y = val)),
          _axisSlider('Linear Z', z, (val) => setState(() => z = val)),
          _axisSlider('Angular Roll', roll, (val) => setState(() => roll = val)),
          _axisSlider('Angular Pitch', pitch, (val) => setState(() => pitch = val)),
          _axisSlider('Angular Yaw', yaw, (val) => setState(() => yaw = val)),
        ],
      ),
    );
  }

  Widget _axisSlider(String label, double value, ValueChanged<double> onChanged) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(2)}'),
          Slider(value: value, min: -10, max: 10, divisions: 100, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      appBar: AppBar(
        title: Text(widget.isJoystick ? 'Joystick Control' : 'Custom Message'),
        backgroundColor: Colors.blueAccent,
      ),
      body: widget.isJoystick
          ? Column(
              children: [
                _commonTopicUI(), // topic + buttons common
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Slider'),
                    Tab(text: 'Tap Buttons'),
                  ],
                  indicatorColor: Colors.white,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _sliderJoystickUI(),
                      TapControllerTab(
                        rosManager: widget.rosManager,
                        topicController: _topicController,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _customMessageUI(),
    );
  }
}
