import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tel/widget/button.dart';
import 'package:telephony/telephony.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class StreamingScreen extends StatefulWidget {
  @override
  _StreamingScreenState createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  late YoutubePlayerController _controller;
  double dataLimitMB = 50.0; // Default data limit
  double usedDataMB = 0.0;
  String networkType = "Unknown";
  double speedMbps = 0.0;
  Timer? _timer;
  static const platform = MethodChannel('data_usage');
  TextEditingController dataLimitController = TextEditingController();
  int initialDataUsage = 0;
  int previousDataUsage = 0;
  DateTime? previousTimestamp;

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'KLuTLF3x9sA',
      flags: YoutubePlayerFlags(autoPlay: false, mute: false),
    );
    _checkNetworkType();
  }

  void checkNetworkType() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      if (connectivityResult == ConnectivityResult.mobile) {
        networkType = "4G/5G"; // Assumption, refine as needed
      } else {
        networkType = "Not Cellular";
      }
    });
  }

  Future<void> _checkNetworkType() async {
    Telephony telephony = Telephony.instance;
    NetworkType? netType = await telephony.dataNetworkType;
    setState(() {
      switch (netType) {
        case NetworkType.LTE:
          networkType = "4G";
          break;
        case NetworkType.NR:
          networkType = "5G";
          break;
        case NetworkType.HSPA:
        case NetworkType.HSPAP:
          networkType = "3G";
          break;
        default:
          networkType = "Unknown";
      }
    });
  }

  Future<bool> _isMobileDataOn() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile;
  }

  Future<int> getMobileDataUsage() async {
    try {
      final int dataUsed = await platform.invokeMethod('getMobileDataUsage');
      return dataUsed;
    } on PlatformException catch (e) {
      print("Failed to get data usage: '${e.message}'.");
      return 0;
    }
  }

  Future<double> getRealTimeInternetSpeed() async {
    int initialDataUsage = await getMobileDataUsage();
    DateTime startTime = DateTime.now();

    // Wait for 1 second to measure data usage difference
    await Future.delayed(Duration(seconds: 1));

    int finalDataUsage = await getMobileDataUsage();
    DateTime endTime = DateTime.now();

    int dataUsedBytes = finalDataUsage - initialDataUsage;
    double timeElapsedSeconds =
        endTime.difference(startTime).inMilliseconds / 1000.0;

    if (timeElapsedSeconds > 0 && dataUsedBytes > 0) {
      double speedMbps = (dataUsedBytes * 8) /
          (1000 * 1000 * timeElapsedSeconds); // Convert to Mbps
      return speedMbps;
    }
    return 0.0; // Return 0 if no data was used or time is invalid
  }

  void startStreaming() async {
    if (!await _isMobileDataOn()) {
      _showErrorDialog(
          "No Mobile Data", "Please enable mobile data to stream.");
      return;
    }

    _controller.play();
    initialDataUsage = await getMobileDataUsage();
    usedDataMB = 0.0;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      double currentSpeed = await getRealTimeInternetSpeed();

      setState(() {
        speedMbps = currentSpeed;
      });

      int currentDataUsage = await getMobileDataUsage();
      usedDataMB = (currentDataUsage - initialDataUsage) /
          (1024 * 1024); // Convert bytes to MB

      if (usedDataMB >= dataLimitMB) {
        stopStreaming();
      }
    });
  }

  void stopStreaming() {
    _controller.pause();
    _timer?.cancel();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    dataLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("YouTube Streaming"),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            YoutubePlayer(controller: _controller),
            const SizedBox(height: 20),
            Text("Network: $networkType"),
            const SizedBox(height: 10),
            Text("Speed: ${speedMbps.toStringAsFixed(2)} Mbps"),
            const SizedBox(height: 10),
            Text(
                "Used Data: ${usedDataMB.toStringAsFixed(2)} MB / $dataLimitMB MB"),
            const SizedBox(height: 10),
            TextField(
              controller: dataLimitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter Data Limit (MB)",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  dataLimitMB = double.tryParse(value) ?? 50.0;
                });
              },
            ),
            const SizedBox(height: 16),
            Button(
              onPressed: startStreaming,
              width: MediaQuery.of(context).size.width * 0.9,
              height: 60,
              text: 'Start Streaming',
            ),
            const SizedBox(height: 16),
            if (usedDataMB >= dataLimitMB)
              Text("Data limit reached!", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
