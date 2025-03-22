import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:tel/widget/button.dart';
import 'package:telephony/telephony.dart';

class PhoneCallScreen extends StatefulWidget {
  @override
  _PhoneCallScreenState createState() => _PhoneCallScreenState();
}

class _PhoneCallScreenState extends State<PhoneCallScreen> {
  static const platform = MethodChannel('call_control');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  Telephony telephony = Telephony.instance;
  PhoneStateStatus? lastState;
  bool _callEndedByUser = false;
  bool _showEndCall = false;
  Timer? _callTimer;
  String callStatus = "Waiting for call...";
  DateTime? _callStartTime;
  String phoneNumber = "";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenToCallState();
  }

  void _listenToCallState() {
    PhoneState.stream.listen((PhoneState event) {
      setState(() {
        print(event.duration);
        if (event.status == PhoneStateStatus.CALL_STARTED) {
          callStatus = "Outgoing call in progress...";
          int duration = int.tryParse(_durationController.text.trim()) ?? 0;
          _callStartTime = DateTime.now();
        } else if (event.status == PhoneStateStatus.CALL_ENDED) {
          callStatus = _determineCallEndReason();
        }
      });
    });
  }

  String _determineCallEndReason() {
    _callTimer?.cancel();
    if (_callStartTime == null) {
      return "Call ended: Unknown reason";
    }

    final int callDuration =
        DateTime.now().difference(_callStartTime!).inSeconds;

    if (callStatus == "Call ended: Duration Over") {
      return "Call ended: Duration Over";
    } else if (_callEndedByUser) {
      return "Call ended: By You";
    } else if (callDuration < 5) {
      return "Call ended: By Receiver";
    } else {
      return "Call ended: Network Issue or Other End";
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.phone,
    ].request();
  }

  Future<void> _hangUpCall() async {
    try {
      _callEndedByUser = true;
      _showEndCall = false;
      await platform.invokeMethod('hangUpCall');
    } on PlatformException catch (e) {
      print("Failed to hang up call: ${e.message}");
    }
  }

  Future<void> _makeCall() async {
    int duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (phoneNumber.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please enter a valid phone number and duration")),
      );
      return;
    }

    bool? callMade = await FlutterPhoneDirectCaller.callNumber(phoneNumber);

    if (callMade == true) {
      setState(() {
        callStatus = "Call started...";
        _showEndCall = true;
      });

      _callTimer = Timer(Duration(seconds: duration), () async {
        await _hangUpCall();
        setState(() {
          callStatus = "Call ended: Duration Over";
        });
      });
    } else {
      setState(() {
        callStatus = "Failed to start call";
      });
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trigger Phone Call"),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              IntlPhoneField(
                controller: _phoneController,
                autovalidateMode: AutovalidateMode.disabled,
                disableLengthCheck: true,
                dropdownIconPosition: IconPosition.trailing,
                decoration: InputDecoration(
                  labelText: "Enter Phone Number",
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'IN',
                onChanged: (value) {
                  setState(() {
                    phoneNumber = value.completeNumber;
                  });
                },
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Call Duration (seconds)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Button(
                    onPressed: _makeCall,
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 60,
                    text: 'Make Call',
                  ),
                  _showEndCall
                      ? const SizedBox(
                          height: 10,
                        )
                      : const SizedBox.shrink(),
                  _showEndCall
                      ? Button(
                          onPressed: _hangUpCall,
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: 60,
                          text: 'End Call',
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              SizedBox(height: 20),
              Text(
                "Call Status: $callStatus",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
