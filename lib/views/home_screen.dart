import 'package:flutter/material.dart';
import 'package:tel/widget/button.dart';

import 'message_screen.dart';
import 'phone_call_screen.dart';
import 'streaming_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Telephony Services'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Button(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PhoneCallScreen(),
                  ),
                );
              },
              width: MediaQuery.of(context).size.width * 0.9,
              height: 60,
              text: 'Trigger Voice Call',
            ),
            const SizedBox(
              height: 30,
            ),
            Button(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MessageScreen(),
                  ),
                );
              },
              width: MediaQuery.of(context).size.width * 0.9,
              height: 60,
              text: 'Send SMS',
            ),
            const SizedBox(
              height: 30,
            ),
            Button(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StreamingScreen(),
                  ),
                );
              },
              width: MediaQuery.of(context).size.width * 0.9,
              height: 60,
              text: 'Streaming',
            ),
          ],
        ),
      ),
    );
  }
}
