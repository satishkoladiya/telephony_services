import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tel/widget/button.dart';
import 'package:telephony/telephony.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  static const platformSMS = MethodChannel('sms_sender');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  String deliveryStatus = "Status: Not Sent";
  Telephony telephony = Telephony.instance;
  String phoneNumber = "";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.phone,
    ].request();

    bool? permission = await telephony.requestSmsPermissions;
    if (permission != true) {
      setState(() {
        deliveryStatus = "SMS Permission Denied!";
      });
    }
  }

  void _sendSMS() async {
    setState(() {
      deliveryStatus = "";
    });
    String phone = _phoneController.text.trim();
    String message = messageController.text.trim();

    if (phone.isEmpty || message.isEmpty) {
      setState(() {
        deliveryStatus = "Enter valid phone number & message.";
      });
      return;
    }

    try {
      final String result = await platformSMS.invokeMethod('sendSms', {
        "phone": phone,
        "message": message,
      });

      setState(() {
        deliveryStatus = "SMS Status: $result";
      });
    } on PlatformException catch (e) {
      setState(() {
        deliveryStatus = "Failed to send SMS: ${e.message}";
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send SMS"),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              controller: messageController,
              keyboardType: TextInputType.multiline,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: "Message",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Button(
              onPressed: _sendSMS,
              width: MediaQuery.of(context).size.width * 0.9,
              height: 60,
              text: 'Send SMS',
            ),
            const SizedBox(height: 20),
            Text(deliveryStatus, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
