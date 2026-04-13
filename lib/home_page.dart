import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ros_manager.dart';
import 'publisher_page.dart';
import 'sensor_tab.dart';
import 'settings_page.dart';
import 'others_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final RosManager _rosManager = RosManager();
  String _rosIp = "ws://10.66.17.103:9090";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString('ros_ip');
    if (savedIp != null) setState(() => _rosIp = savedIp);
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ros_ip', ip);
  }

  void _connect() {
    _rosManager.connect(_rosIp);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Connected to $_rosIp')));
  }

  void _openSettings() async {
    // Prepare IP for display (remove prefix/suffix if present)
    String displayIp = _rosIp;
    if (displayIp.startsWith("ws://")) {
      displayIp = displayIp.substring(5);
    }
    if (displayIp.endsWith(":9090")) {
      displayIp = displayIp.substring(0, displayIp.length - 5);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsPage(ip: displayIp)),
    );

    if (result != null && result is String) {
      // Re-add prefix/suffix if missing before saving
      String fullIp = result.trim();
      if (!fullIp.startsWith("ws://")) {
        fullIp = "ws://$fullIp";
      }
      if (!fullIp.endsWith(":9090")) {
        // Check if it already has a different port, if not add default
        if (!fullIp.contains(RegExp(r':\d+$'))) {
           fullIp = "$fullIp:9090";
        }
      }

      setState(() {
        _rosIp = fullIp;
        _rosManager.disconnect();
        _saveIp(fullIp);
      });
    }
  }

  void _openPublisher({bool isJoystick = false}) {
    if (!_rosManager.isConnected) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please connect first')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PublisherPage(rosManager: _rosManager, isJoystick: isJoystick),
      ),
    );
  }

  Widget _messageGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
        children: [
          GestureDetector(
            onTap: () => _openPublisher(isJoystick: false),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Custom Message',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _openPublisher(isJoystick: true),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Joystick Control',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rosManager.disconnect();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BROS2'),
        actions: [
          IconButton(onPressed: _connect, icon: const Icon(Icons.usb)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') _openSettings();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Messages'),
            Tab(text: 'Sensors'),
            Tab(text: 'Others'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _messageGrid(),
          SensorTab(rosManager: _rosManager),
          OthersTab(rosManager: _rosManager),
        ],
      ),
    );
  }
}